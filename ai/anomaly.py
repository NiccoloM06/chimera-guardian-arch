#!/usr/bin/env python3

# =======================================================================================
#  LOCAL ANOMALY DETECTION ENGINE | CHIMERA GUARDIAN ARCH
#  Uses an Isolation Forest model to detect anomalous patterns in system logs.
#  This script operates completely offline and sends signals to the Guardian Daemon.
# =======================================================================================

import os
import json
import socket
import argparse
import numpy as np
from datetime import datetime
from sklearn.ensemble import IsolationForest
import joblib

# --- GLOBAL CONFIGURATION ---
# These paths are defined to ensure consistency within the framework.
CHIMERA_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
LOG_DIR = os.path.join(CHIMERA_ROOT, 'logs')
MODEL_PATH = os.path.join(CHIMERA_ROOT, 'ai', 'isolation_forest.joblib')
SOCKET_PATH = "/run/chimera/guardian.sock"

# The log file to use for training (should represent normal system activity).
TRAINING_LOG_BASELINE = os.path.join(LOG_DIR, "baseline_activity.log")

# The log file to audit for anomalies (in a real scenario, this would be a live system log).
AUDIT_LOG_TARGET = os.path.join(LOG_DIR, "chimera-install-latest.log") # Example target

# --- STRUCTURED LOGGER ---
def log(level, message, data=None):
    """Writes a structured JSON log entry to stdout."""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "source": "anomaly_detector",
        "level": level.upper(),
        "message": message,
    }
    if data:
        log_entry.update(data)
    print(json.dumps(log_entry))

# --- FEATURE ENGINEERING ---
def featurize_log_entry(entry: str) -> np.ndarray:
    """
    Converts a raw log string into a numerical feature vector for the model.
    This is the "intelligence" of the detector.
    """
    entry = entry.strip().lower()
    
    # Define keywords that might indicate suspicious activity.
    suspicious_keywords = ["failed", "denied", "error", "refused", "invalid", "segfault", "authentication failure"]
    
    features = [
        len(entry),  # Feature 1: Length of the log message.
        sum(c.isdigit() for c in entry),  # Feature 2: Count of numerical digits.
        sum(c in "!@#$%^&*()" for c in entry),  # Feature 3: Count of special characters.
        sum(entry.count(keyword) for keyword in suspicious_keywords) # Feature 4: Count of suspicious keywords.
    ]
    
    # Reshape for scikit-learn compatibility.
    return np.array(features).reshape(1, -1)

# --- DAEMON COMMUNICATION ---
def signal_daemon(anomaly_details: dict):
    """Sends a signal to the Guardian Daemon via a Unix socket."""
    payload = {
        "event": "ANOMALY_DETECTED",
        "source": "ai_audit",
        "details": anomaly_details
    }
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCKET_PATH)
            s.sendall(json.dumps(payload).encode('utf-8'))
        log("SUCCESS", "Successfully sent anomaly signal to Guardian Daemon.")
    except (ConnectionRefusedError, FileNotFoundError):
        log("WARN", "Could not connect to Guardian Daemon socket. Is it running?")
    except Exception as e:
        log("ERROR", f"Failed to send signal to daemon: {e}")

# --- CORE FUNCTIONS: TRAIN & AUDIT ---
def train_model():
    """Trains the Isolation Forest model on a baseline log file."""
    log("INFO", f"Starting model training using baseline log: {TRAINING_LOG_BASELINE}")

    if not os.path.exists(TRAINING_LOG_BASELINE):
        log("ERROR", "Training baseline log not found. Please create it first.")
        log("ERROR", "Example: `journalctl -p 6 --since '1 day ago' > logs/baseline_activity.log`")
        return

    try:
        with open(TRAINING_LOG_BASELINE, 'r') as f:
            log_entries = f.readlines()
    except Exception as e:
        log("ERROR", f"Could not read baseline log file: {e}")
        return

    if not log_entries:
        log("ERROR", "Baseline log is empty. Cannot train model.")
        return

    log("INFO", f"Featurizing {len(log_entries)} log entries...")
    feature_matrix = np.vstack([featurize_log_entry(entry)[0] for entry in log_entries])
    
    log("INFO", "Training Isolation Forest model...")
    # 'auto' contamination is a modern default. random_state ensures reproducibility.
    model = IsolationForest(contamination='auto', random_state=42, n_estimators=100)
    model.fit(feature_matrix)
    
    log("INFO", f"Saving trained model to: {MODEL_PATH}")
    joblib.dump(model, MODEL_PATH)
    log("SUCCESS", "Model training complete and saved.")

def run_audit():
    """Audits a target log file using the pre-trained model."""
    log("INFO", f"Starting audit of target log: {AUDIT_LOG_TARGET}")

    if not os.path.exists(MODEL_PATH):
        log("ERROR", "Trained model not found. Please run with '--train' first.")
        return
        
    if not os.path.exists(AUDIT_LOG_TARGET):
        log("ERROR", f"Target log file for audit not found: {AUDIT_LOG_TARGET}")
        return

    log("INFO", "Loading pre-trained model...")
    model = joblib.load(MODEL_PATH)
    
    log("INFO", "Scanning for anomalies...")
    anomalies_found = 0
    try:
        with open(AUDIT_LOG_TARGET, 'r') as f:
            for i, line in enumerate(f):
                if not line.strip():
                    continue
                
                features = featurize_log_entry(line)
                prediction = model.predict(features)
                
                # predict() returns -1 for outliers (anomalies) and 1 for inliers (normal).
                if prediction[0] == -1:
                    anomalies_found += 1
                    anomaly_data = {"line_number": i + 1, "log_entry": line.strip()}
                    log("WARN", "Anomaly detected!", data=anomaly_data)
                    signal_daemon(anomaly_data)
                    
    except Exception as e:
        log("ERROR", f"An error occurred during audit: {e}")
        return

    if anomalies_found == 0:
        log("SUCCESS", "Audit complete. No anomalies found.")
    else:
        log("WARN", f"Audit complete. Found {anomalies_found} potential anomalies.")

# --- MAIN CLI ENTRYPOINT ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Chimera Guardian Arch - Local Anomaly Detection Engine.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "--train",
        action="store_true",
        help="Train the model using the baseline log file defined in TRAINING_LOG_BASELINE."
    )
    parser.add_argument(
        "--audit",
        action="store_true",
        help="Run an audit on the target log file using the pre-trained model."
    )
    args = parser.parse_args()

    if args.train:
        train_model()
    elif args.audit:
        run_audit()
    else:
        parser.print_help()