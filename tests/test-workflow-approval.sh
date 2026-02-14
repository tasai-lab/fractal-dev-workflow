#!/bin/bash
# test-workflow-approval.sh - ワークフロー承認機能のテスト

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOW_MANAGER="$PROJECT_ROOT/scripts/workflow-manager.sh"
TEST_WORKFLOW_DIR="/tmp/test-workflow-$$"

# テスト環境セットアップ
setup() {
    export WORKFLOW_DIR="$TEST_WORKFLOW_DIR"
    mkdir -p "$WORKFLOW_DIR"
}

# テスト環境クリーンアップ
teardown() {
    rm -rf "$TEST_WORKFLOW_DIR"
}

# テストカウンター
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

# Test 1: 8フェーズのワークフロー作成
test_create_8_phase_workflow() {
    echo "Test 1: 8フェーズのワークフロー作成"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")
    local state=$($WORKFLOW_MANAGER get "$wf_id")

    # フェーズ数確認
    local phase_count=$(echo "$state" | jq '.phases | length')
    assert_equals "8" "$phase_count" "フェーズ数は8であること"

    # 各フェーズが存在することを確認
    for i in {1..8}; do
        local phase_status=$(echo "$state" | jq -r ".phases[\"$i\"].status")
        assert_equals "pending" "$phase_status" "Phase $i のステータスはpending"
    done
}

# Test 2: Codex承認の記録
test_codex_approval() {
    echo "Test 2: Codex承認の記録"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # Phase 4 にCodex承認を記録
    bash -c "source $WORKFLOW_MANAGER; approve '$wf_id' '4' 'codex'" 2>/dev/null || true

    local state=$($WORKFLOW_MANAGER get "$wf_id")
    local codex_approved=$(echo "$state" | jq -r '.phases["4"].codexApprovedAt // empty')

    assert_not_empty "$codex_approved" "Phase 4 のcodexApprovedAtが設定されていること"

    # userApprovedAtは未設定であること
    local user_approved=$(echo "$state" | jq -r '.phases["4"].userApprovedAt // empty')
    assert_equals "" "$user_approved" "Phase 4 のuserApprovedAtは未設定であること"
}

# Test 3: User承認の記録
test_user_approval() {
    echo "Test 3: User承認の記録"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # Phase 4 にUser承認を記録（デフォルト）
    bash -c "source $WORKFLOW_MANAGER; approve '$wf_id' '4'" 2>/dev/null || true

    local state=$($WORKFLOW_MANAGER get "$wf_id")
    local user_approved=$(echo "$state" | jq -r '.phases["4"].userApprovedAt // empty')

    assert_not_empty "$user_approved" "Phase 4 のuserApprovedAtが設定されていること"

    # statusがcompletedになること
    local status=$(echo "$state" | jq -r '.phases["4"].status')
    assert_equals "completed" "$status" "Phase 4 のstatusはcompletedであること"
}

# Test 4: 2段階承認（Codex → User）
test_two_stage_approval() {
    echo "Test 4: 2段階承認（Codex → User）"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # Codex承認
    bash -c "source $WORKFLOW_MANAGER; approve '$wf_id' '4' 'codex'" 2>/dev/null || true

    # User承認
    bash -c "source $WORKFLOW_MANAGER; approve '$wf_id' '4' 'user'" 2>/dev/null || true

    local state=$($WORKFLOW_MANAGER get "$wf_id")
    local codex_approved=$(echo "$state" | jq -r '.phases["4"].codexApprovedAt // empty')
    local user_approved=$(echo "$state" | jq -r '.phases["4"].userApprovedAt // empty')

    assert_not_empty "$codex_approved" "Phase 4 のcodexApprovedAtが設定されていること"
    assert_not_empty "$user_approved" "Phase 4 のuserApprovedAtが設定されていること"
}

# テスト実行
main() {
    echo "==================================="
    echo "Workflow Approval Tests"
    echo "==================================="

    setup

    test_create_8_phase_workflow
    test_codex_approval
    test_user_approval
    test_two_stage_approval

    teardown

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
