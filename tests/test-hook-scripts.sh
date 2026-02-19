#!/bin/bash
# test-hook-scripts.sh - フックスクリプトのユニットテスト

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW_MANAGER="$PROJECT_ROOT/scripts/workflow-manager.sh"
TEST_DIR="/tmp/test-hooks-$$"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# アサーション関数
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: $message"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -n "$value" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: $message (value is empty)"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    TESTS_RUN=$((TESTS_RUN + 1))

    if echo "$haystack" | grep -q "$needle"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: $message"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: $message"
        echo "    Expected to contain: $needle"
        echo "    Actual: $haystack"
    fi
}

setup() {
    export WORKFLOW_DIR="$TEST_DIR"
    mkdir -p "$TEST_DIR"
}

cleanup() {
    rm -rf "$TEST_DIR"
}

# Test 1: check-approval.sh がアクティブWFなし時にパスすること
test_check_approval_no_active_wf() {
    echo "Test 1: アクティブWFなし時に承認チェックがパスすること"

    # アクティブWFが存在しないTEST_DIRを使用してcheck-approval.shを実行
    # stdinを消費するためechoでパイプ、終了コード0を期待する
    local exit_code=0
    echo "" | WORKFLOW_DIR="$TEST_DIR" bash "$PROJECT_ROOT/hooks/check-approval.sh" 2>/dev/null || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        TESTS_RUN=$((TESTS_RUN + 1)); TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: アクティブWFなし時にcheck-approval.shがexit 0を返すこと"
    else
        TESTS_RUN=$((TESTS_RUN + 1)); TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: check-approval.shがexit $exit_code を返した"
    fi
}

# Test 2: session-init.sh の出力が空またはJSONとして有効であること
# session-init.sh は get_workflow_dir() でパスを決定するため WORKFLOW_DIR 環境変数は無効
# アクティブWFが存在しなければ空出力、存在すれば有効なJSON出力を返す仕様を検証する
test_session_init_output_format() {
    echo "Test 2: session-init.shの出力が空または有効なJSONであること"

    local output
    output=$(bash "$PROJECT_ROOT/hooks/session-init.sh" 2>/dev/null || true)

    if [[ -z "$output" ]]; then
        TESTS_RUN=$((TESTS_RUN + 1)); TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: アクティブWFなし時にsession-init.shが空出力すること"
    else
        # 出力がある場合は有効なJSONであることを確認
        local is_valid_json
        is_valid_json=$(echo "$output" | jq 'has("hookSpecificOutput")' 2>/dev/null || echo "false")
        if [[ "$is_valid_json" == "true" ]]; then
            TESTS_RUN=$((TESTS_RUN + 1)); TESTS_PASSED=$((TESTS_PASSED + 1))
            echo "  PASS: アクティブWFあり時にsession-init.shが有効なJSON（hookSpecificOutput）を出力すること"
        else
            TESTS_RUN=$((TESTS_RUN + 1)); TESTS_FAILED=$((TESTS_FAILED + 1))
            echo "  FAIL: session-init.shの出力が無効なフォーマット"
            echo "    Output: $output"
        fi
    fi
}

# Test 3: workflow-manager.sh の validate_workflow_id が正しいフォーマットを受け入れること
test_validate_valid_id() {
    echo "Test 3: 正しいフォーマットのIDが受け入れられること"

    local wf_id
    wf_id=$(WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER create "Valid ID test")
    local state
    state=$(WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER get "$wf_id")
    assert_not_empty "$state" "正しいIDでget可能"
}

# Test 4: Phase 4未承認時にPhase 5への遷移がブロックされること
test_phase5_blocked_without_phase4_approval() {
    echo "Test 4: Phase 4未承認時にPhase 5への遷移がブロックされること"

    local wf_id
    wf_id=$(WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER create "Block test")
    WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER set-phase "$wf_id" 4

    local result
    result=$(WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER set-phase "$wf_id" 5 2>&1 || true)
    assert_contains "$result" "ERROR" "Phase 4未承認でPhase 5がブロックされること"
}

# Test 5: Phase 4両方承認後にPhase 5への遷移が許可されること
test_phase5_allowed_after_full_approval() {
    echo "Test 5: Phase 4両方承認後にPhase 5への遷移が許可されること"

    local wf_id
    wf_id=$(WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER create "Approve test")
    WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER set-phase "$wf_id" 4
    WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER approve "$wf_id" 4 codex
    WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER approve "$wf_id" 4 user
    WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER set-phase "$wf_id" 5

    local state
    state=$(WORKFLOW_DIR="$TEST_DIR" $WORKFLOW_MANAGER get "$wf_id")
    local phase
    phase=$(echo "$state" | jq -r '.currentPhase')
    assert_equals "5" "$phase" "Phase 4両方承認後にPhase 5への遷移が成功すること"
}

main() {
    echo "==================================="
    echo "Hook Scripts Tests"
    echo "==================================="

    setup
    trap cleanup EXIT

    test_check_approval_no_active_wf
    test_session_init_output_format
    test_validate_valid_id
    test_phase5_blocked_without_phase4_approval
    test_phase5_allowed_after_full_approval

    echo ""
    echo "==================================="
    echo "Test Results"
    echo "==================================="
    echo "Tests run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
