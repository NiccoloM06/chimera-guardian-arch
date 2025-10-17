#!/usr/bin/env python3

# =======================================================================================
#  UNIT TESTS FOR ANOMALY DETECTION ENGINE | CHIMERA GUARDIAN ARCH
#  Uses pytest and mocker to test the ai/anomaly.py module.
# =======================================================================================

import os
import sys
import json
import pytest
import numpy as np
import joblib
from unittest.mock import patch, MagicMock, mock_open

# --- Add Project Root to Python Path ---
# This allows importing the 'ai.anomaly' module directly
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

# --- Import the module to be tested ---
# Note: This might raise errors if scikit-learn or joblib aren't installed in the test env
try:
    from ai import anomaly
except ImportError as e:
    pytest.skip(f"Skipping anomaly tests: {e}", allow_module_level=True)

# --- Test Cases ---

def test_log_output_format(capsys):
    """Verify that the log function produces valid JSON."""
    anomaly.log("INFO", "Test message", data={"key": "value"})
    captured = capsys.readouterr()
    log_output = captured.out.strip()
    
    assert log_output, "Log output should not be empty"
    try:
        log_json = json.loads(log_output)
        assert log_json["level"] == "INFO"
        assert log_json["message"] == "Test message"
        assert log_json["source"] == "anomaly_detector"
        assert log_json["key"] == "value"
        assert "timestamp" in log_json
    except json.JSONDecodeError:
        pytest.fail(f"Log output is not valid JSON: {log_output}")

def test_featurize_log_entry_normal():
    """Test feature extraction on a normal log line."""
    log_line = "[2025-10-17 14:30:00] [INFO] System update started."
    features = anomaly.featurize_log_entry(log_line)
    assert isinstance(features, np.ndarray), "Output should be a numpy array"
    assert features.shape == (1, 4), "Feature vector should have shape (1, 4)"
    # Expected: [length, digits, specials, suspicious_count]
    assert np.array_equal(features, np.array([[46, 10, 2, 0]]))

def test_featurize_log_entry_suspicious():
    """Test feature extraction on a log line with suspicious keywords."""
    log_line = "authentication failed for user root"
    features = anomaly.featurize_log_entry(log_line)
    assert features[0, 3] == 1, "Suspicious keyword count should be 1" # Feature index 3

def test_train_model_no_baseline(mocker, capsys):
    """Test training when the baseline log file doesn't exist."""
    mocker.patch('os.path.exists', return_value=False)
    anomaly.train_model()
    captured = capsys.readouterr()
    assert "[ERROR]" in captured.out
    assert "Training baseline log not found" in captured.out

def test_train_model_empty_baseline(mocker, capsys):
    """Test training when the baseline log file is empty."""
    mocker.patch('os.path.exists', return_value=True)
    mocker.patch('builtins.open', mock_open(read_data=""))
    anomaly.train_model()
    captured = capsys.readouterr()
    assert "[ERROR]" in captured.out
    assert "Baseline log is empty" in captured.out

@patch('ai.anomaly.IsolationForest') # Mock the model itself
@patch('joblib.dump')              # Mock the saving function
def test_train_model_success(mock_joblib_dump, mock_isoforest, mocker, capsys):
    """Test successful model training and saving."""
    # Mock filesystem operations
    mocker.patch('os.path.exists', return_value=True)
    mocker.patch('builtins.open', mock_open(read_data="[INFO] Normal log entry\n[WARN] Another normal entry"))
    
    # Mock the IsolationForest instance methods
    mock_model_instance = MagicMock()
    mock_isoforest.return_value = mock_model_instance
    
    anomaly.train_model()
    
    # Assertions
    captured = capsys.readouterr()
    assert "[SUCCESS]" in captured.out
    assert "Model training complete and saved" in captured.out
    mock_isoforest.assert_called_once() # Was the model constructor called?
    mock_model_instance.fit.assert_called_once() # Was the fit method called?
    mock_joblib_dump.assert_called_once_with(mock_model_instance, anomaly.MODEL_PATH) # Was dump called correctly?

def test_run_audit_no_model(mocker, capsys):
    """Test audit when the model file doesn't exist."""
    mocker.patch('os.path.exists', side_effect=lambda path: path != anomaly.MODEL_PATH)
    anomaly.run_audit()
    captured = capsys.readouterr()
    assert "[ERROR]" in captured.out
    assert "Trained model not found" in captured.out

def test_run_audit_no_target_log(mocker, capsys):
    """Test audit when the target log file doesn't exist."""
    mocker.patch('os.path.exists', side_effect=lambda path: path != anomaly.AUDIT_LOG_TARGET)
    anomaly.run_audit()
    captured = capsys.readouterr()
    assert "[ERROR]" in captured.out
    assert "Target log file for audit not found" in captured.out

@patch('joblib.load')
@patch('ai.anomaly.signal_daemon') # Mock the daemon signaling function
def test_run_audit_detects_anomaly(mock_signal_daemon, mock_joblib_load, mocker, capsys):
    """Test audit correctly identifies an anomaly and signals the daemon."""
    # Mock model loading
    mock_model_instance = MagicMock()
    mock_model_instance.predict.return_value = np.array([-1]) # Predict anomaly
    mock_joblib_load.return_value = mock_model_instance
    
    # Mock filesystem operations
    mocker.patch('os.path.exists', return_value=True)
    mocker.patch('builtins.open', mock_open(read_data="[ERROR] Something went wrong!\n"))

    anomaly.run_audit()
    
    captured = capsys.readouterr()
    assert "[WARN]" in captured.out
    assert "Anomaly detected!" in captured.out
    mock_model_instance.predict.assert_called_once()
    mock_signal_daemon.assert_called_once() # Check if daemon was signaled

@patch('joblib.load')
@patch('ai.anomaly.signal_daemon')
def test_run_audit_no_anomaly(mock_signal_daemon, mock_joblib_load, mocker, capsys):
    """Test audit correctly identifies normal entries."""
    mock_model_instance = MagicMock()
    mock_model_instance.predict.return_value = np.array([1]) # Predict normal
    mock_joblib_load.return_value = mock_model_instance
    
    mocker.patch('os.path.exists', return_value=True)
    mocker.patch('builtins.open', mock_open(read_data="[INFO] Everything is fine.\n"))

    anomaly.run_audit()
    
    captured = capsys.readouterr()
    assert "[SUCCESS]" in captured.out
    assert "No anomalies found" in captured.out
    mock_model_instance.predict.assert_called_once()
    mock_signal_daemon.assert_not_called() # Daemon should NOT be signaled

@patch('socket.socket')
def test_signal_daemon_connection_error(mock_socket, capsys):
    """Test daemon signaling when the socket is unavailable."""
    mock_socket_instance = MagicMock()
    mock_socket_instance.connect.side_effect = ConnectionRefusedError # Simulate connection failure
    mock_socket.return_value.__enter__.return_value = mock_socket_instance

    anomaly.signal_daemon({"detail": "test"})
    
    captured = capsys.readouterr()
    assert "[WARN]" in captured.out
    assert "Could not connect to Guardian Daemon socket" in captured.out

@patch('socket.socket')
def test_signal_daemon_success(mock_socket, capsys):
    """Test successful daemon signaling."""
    mock_socket_instance = MagicMock()
    mock_socket.return_value.__enter__.return_value = mock_socket_instance

    test_payload = {"detail": "test anomaly"}
    anomaly.signal_daemon(test_payload)
    
    captured = capsys.readouterr()
    assert "[SUCCESS]" in captured.out
    assert "Successfully sent anomaly signal" in captured.out
    # Check if sendall was called with the correctly formatted JSON payload
    mock_socket_instance.sendall.assert_called_once()
    sent_data_bytes = mock_socket_instance.sendall.call_args[0][0]
    sent_data_json = json.loads(sent_data_bytes.decode('utf-8'))
    assert sent_data_json["event"] == "ANOMALY_DETECTED"
    assert sent_data_json["source"] == "ai_audit"
    assert sent_data_json["details"] == test_payload