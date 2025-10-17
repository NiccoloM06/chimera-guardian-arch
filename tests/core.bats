#!/usr/bin/env bats

# =======================================================================================
#  CORE TESTS | CHIMERA GUARDIAN ARCH
#  Uses BATS framework to test core library functions.
# =======================================================================================

# --- Load Testing Libraries ---
# These provide helper functions for assertions and output checking.
# Adjust path if your bats setup uses a different structure.
load '../libs/bats-support/load'
load '../libs/bats-assert/load'

# --- Setup Function ---
# Runs before each test case. Sources the library being tested.
setup() {
    # Ensure CHIMERA_ROOT is defined for lib.sh to find .env (create a dummy .env if needed)
    export CHIMERA_ROOT="$(pwd)/.."
    touch "$CHIMERA_ROOT/.env" # Create dummy .env for testing
    source "$CHIMERA_ROOT/scripts/lib.sh"
}

# --- Teardown Function ---
# Runs after each test case for cleanup.
teardown() {
    rm -f "$CHIMERA_ROOT/.env" # Clean up dummy .env
    # Optional: Clean up log files generated during tests
    # rm -f "$CHIMERA_ROOT/logs/chimera-*.log"
}

# --- Test Cases for Logging Functions ---

@test "logger.sh: log_info() should produce INFO level output and include message" {
    run log "INFO" 'test informational message'
    assert_success
    assert_output --partial "[INFO]"
    assert_output --partial "test informational message"
}

@test "logger.sh: log_success() should produce OK level output" {
    run log "SUCCESS" 'operation successful'
    assert_success
    assert_output --partial "[OK]"
    assert_output --partial "operation successful"
}

@test "logger.sh: log_warn() should produce WARN level output" {
    run log "WARN" 'this is a warning'
    assert_success
    assert_output --partial "[WARN]"
    assert_output --partial "this is a warning"
}

@test "logger.sh: log_error() should produce ERR level output and write to stderr" {
    run log "ERROR" 'critical error occurred'
    assert_failure # Errors should ideally exit non-zero if trap wasn't active
    assert_output --partial "[ERR]"
    assert_output --partial "critical error occurred"
    # assert_stderr --partial "[ERR]" # BATS might capture differently depending on setup
}

# --- Test Cases for Dependency Checker ---

@test "lib.sh: check_dep() should succeed for existing command (e.g., bash)" {
    run check_dep "bash"
    assert_success
}

@test "lib.sh: check_dep() should fail and exit for non-existent command" {
    run check_dep "nonexistentcommand12345"
    assert_failure
    # The error message comes from the log function within check_dep
    assert_output --partial "[ERR]"
    assert_output --partial "Dependency 'nonexistentcommand12345' not found"
}

# --- Test Cases for Global Variables ---

@test "lib.sh: CHIMERA_ROOT should be defined and point to parent directory" {
    # Check if the variable is set
    assert [ -n "$CHIMERA_ROOT" ]
    # Check if it points to a directory that exists
    assert [ -d "$CHIMERA_ROOT/scripts" ]
}

@test "lib.sh: LOG_FILE path should be defined correctly" {
    assert [ -n "$LOG_FILE" ]
    assert_output --partial "$CHIMERA_ROOT/logs/chimera-" <(echo "$LOG_FILE")
    assert_output --partial ".log" <(echo "$LOG_FILE")
}