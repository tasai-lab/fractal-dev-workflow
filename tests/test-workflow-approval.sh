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

# Test 1: 9フェーズのワークフロー作成
test_create_9_phase_workflow() {
    echo "Test 1: 9フェーズのワークフロー作成"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")
    local state=$($WORKFLOW_MANAGER get "$wf_id")

    # フェーズ数確認
    local phase_count=$(echo "$state" | jq '.phases | length')
    assert_equals "9" "$phase_count" "フェーズ数は9であること"

    # 各フェーズが存在することを確認
    for i in {1..9}; do
        local phase_status=$(echo "$state" | jq -r ".phases[\"$i\"].status")
        assert_equals "pending" "$phase_status" "Phase $i のステータスはpending"
    done
}

# Test 2: Codex承認の記録
test_codex_approval() {
    echo "Test 2: Codex承認の記録"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # Phase 4 にCodex承認を記録（CLI経由）
    $WORKFLOW_MANAGER approve "$wf_id" "4" "codex"

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

    # Phase 4 にUser承認を記録（デフォルト、CLI経由）
    $WORKFLOW_MANAGER approve "$wf_id" "4"

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

    # Codex承認（CLI経由）
    $WORKFLOW_MANAGER approve "$wf_id" "4" "codex"

    # User承認（CLI経由）
    $WORKFLOW_MANAGER approve "$wf_id" "4" "user"

    local state=$($WORKFLOW_MANAGER get "$wf_id")
    local codex_approved=$(echo "$state" | jq -r '.phases["4"].codexApprovedAt // empty')
    local user_approved=$(echo "$state" | jq -r '.phases["4"].userApprovedAt // empty')

    assert_not_empty "$codex_approved" "Phase 4 のcodexApprovedAtが設定されていること"
    assert_not_empty "$user_approved" "Phase 4 のuserApprovedAtが設定されていること"
}

# Test 5: CLI approve の第3引数チェック
test_cli_approve_third_argument() {
    echo "Test 5: CLI approve の第3引数チェック"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # CLI経由でcodex承認を記録
    $WORKFLOW_MANAGER approve "$wf_id" "4" "codex"

    local state=$($WORKFLOW_MANAGER get "$wf_id")
    local codex_approved=$(echo "$state" | jq -r '.phases["4"].codexApprovedAt // empty')

    assert_not_empty "$codex_approved" "CLI approve コマンドでcodex承認が記録されること"

    # CLI経由でuser承認を記録（明示的にuserを指定）
    local wf_id2=$($WORKFLOW_MANAGER create "Test workflow 2")
    $WORKFLOW_MANAGER approve "$wf_id2" "4" "user"

    local state2=$($WORKFLOW_MANAGER get "$wf_id2")
    local user_approved=$(echo "$state2" | jq -r '.phases["4"].userApprovedAt // empty')

    assert_not_empty "$user_approved" "CLI approve コマンドでuser承認が記録されること"
}

# Test 6: is_approved() の新スキーマ対応チェック
test_is_approved_new_schema() {
    echo "Test 6: is_approved() の新スキーマ対応チェック"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # User承認を記録（CLI経由）
    $WORKFLOW_MANAGER approve "$wf_id" "4" "user"

    # is_approved コマンドがuserApprovedAtを確認すること
    local result=$($WORKFLOW_MANAGER is-approved "$wf_id" "4")

    assert_equals "true" "$result" "is_approved() がuserApprovedAtを正しく確認すること"
}

# Test 7: Phase 5への遷移で Phase 4の2段階承認チェック
test_phase_transition_requires_approval() {
    echo "Test 7: Phase 5への遷移で Phase 4の2段階承認チェック"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # Phase 4の承認なしでPhase 5に遷移を試みる（失敗するはず）
    local error_output=$($WORKFLOW_MANAGER set-phase "$wf_id" "5" 2>&1 || echo "ERROR_OCCURRED")

    if echo "$error_output" | grep -q "ERROR"; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: Phase 4の承認なしではPhase 5に遷移できないこと"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: Phase 4の承認なしでPhase 5に遷移できてしまった"
    fi

    # Codex承認のみでPhase 5に遷移を試みる（失敗するはず）
    local wf_id2=$($WORKFLOW_MANAGER create "Test workflow 2")
    $WORKFLOW_MANAGER approve "$wf_id2" "4" "codex"

    local error_output2=$($WORKFLOW_MANAGER set-phase "$wf_id2" "5" 2>&1 || echo "ERROR_OCCURRED")

    if echo "$error_output2" | grep -q "ERROR"; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: Codex承認のみではPhase 5に遷移できないこと"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: Codex承認のみでPhase 5に遷移できてしまった"
    fi

    # 2段階承認後にPhase 5に遷移（成功するはず）
    local wf_id3=$($WORKFLOW_MANAGER create "Test workflow 3")
    $WORKFLOW_MANAGER approve "$wf_id3" "4" "codex"
    $WORKFLOW_MANAGER approve "$wf_id3" "4" "user"

    $WORKFLOW_MANAGER set-phase "$wf_id3" "5"
    local phase=$($WORKFLOW_MANAGER phase "$wf_id3")

    assert_equals "5" "$phase" "2段階承認後にPhase 5に遷移できること"
}

# Test 8: Phase 8への遷移で Phase 7の2段階承認チェック
test_phase_8_transition_requires_approval() {
    echo "Test 8: Phase 8への遷移で Phase 7の2段階承認チェック"

    local wf_id=$($WORKFLOW_MANAGER create "Test workflow")

    # Phase 7まで進める（Phase 4は承認済みと仮定）
    $WORKFLOW_MANAGER approve "$wf_id" "4" "codex"
    $WORKFLOW_MANAGER approve "$wf_id" "4" "user"
    $WORKFLOW_MANAGER set-phase "$wf_id" "7"

    # Phase 7の承認なしでPhase 8に遷移を試みる（失敗するはず）
    local error_output=$($WORKFLOW_MANAGER set-phase "$wf_id" "8" 2>&1 || echo "ERROR_OCCURRED")

    if echo "$error_output" | grep -q "ERROR"; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: Phase 7の承認なしではPhase 8に遷移できないこと"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: Phase 7の承認なしでPhase 8に遷移できてしまった"
    fi

    # 2段階承認後にPhase 8に遷移（成功するはず）
    $WORKFLOW_MANAGER approve "$wf_id" "7" "codex"
    $WORKFLOW_MANAGER approve "$wf_id" "7" "user"

    $WORKFLOW_MANAGER set-phase "$wf_id" "8"
    local phase=$($WORKFLOW_MANAGER phase "$wf_id")

    assert_equals "8" "$phase" "2段階承認後にPhase 8に遷移できること"
}

# Test 9: JSONインジェクション回帰テスト
test_json_injection_resistance() {
    echo "Test 9: JSONインジェクション回帰テスト"

    # ダブルクォートを含む説明でworkflow作成
    local wf_id=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER create 'Task with "quotes" and $special chars')
    # jqでパースできること（有効なJSON）
    local state=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER get "$wf_id")
    local desc=$(echo "$state" | jq -r '.taskDescription')
    assert_not_empty "$desc" "引用符を含む説明でもJSONが正常に生成されること"
}

# Test 10: 連番ID重複回避テスト
test_sequential_id_no_collision() {
    echo "Test 10: 連番ID重複回避テスト"

    local id1=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER create "Test 1")
    local id2=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER create "Test 2")
    local id3=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER create "Test 3")

    if [[ "$id1" != "$id2" && "$id2" != "$id3" && "$id1" != "$id3" ]]; then
        TESTS_RUN=$((TESTS_RUN + 1)); TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: 連続作成でIDが重複しないこと"
    else
        TESTS_RUN=$((TESTS_RUN + 1)); TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: IDが重複した ($id1, $id2, $id3)"
    fi
}

# Test 11: 不正IDフォーマット拒否テスト
test_invalid_id_rejected() {
    echo "Test 11: 不正IDフォーマット拒否テスト"

    local result=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER get "invalid-id" 2>&1 || true)
    if echo "$result" | grep -q "ERROR"; then
        TESTS_RUN=$((TESTS_RUN + 1)); TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: 不正IDが拒否されること"
    else
        TESTS_RUN=$((TESTS_RUN + 1)); TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: 不正IDが受け入れられた"
    fi
}

# Test 12: Tasks連携コマンドテスト
test_tasks_commands() {
    echo "Test 12: Tasks連携コマンドテスト"

    local wf_id=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER create "Tasks test")

    # add-task
    WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER add-task "$wf_id" "t1" "Task 1: 型定義" "5"
    WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER add-task "$wf_id" "t2" "Task 2: API実装" "5"

    # tasks でリスト取得
    local tasks_json=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER tasks "$wf_id")
    local task_count=$(echo "$tasks_json" | jq '.tasks | length')
    assert_equals "2" "$task_count" "add-taskで2件登録されること"

    # update-task
    WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER update-task "$wf_id" "t1" "completed"
    local updated=$(WORKFLOW_DIR="$TEST_WORKFLOW_DIR" $WORKFLOW_MANAGER tasks "$wf_id")
    local t1_status=$(echo "$updated" | jq -r '.tasks[] | select(.taskId == "t1") | .status')
    assert_equals "completed" "$t1_status" "update-taskで状態が更新されること"
}

# Test 13: WORKFLOW_DIR未設定時はget_workflow_dir()と同じパスを使う
test_default_workflow_dir_uses_get_workflow_dir() {
    echo "Test 9: WORKFLOW_DIR未設定時はget_workflow_dir()と同じパスを使う"

    # WORKFLOW_DIRを未設定にしてworkflow-manager.shを実行
    local project_root
    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # workflow-lib.shのget_workflow_dir()が返すパスを取得
    local expected_dir
    expected_dir=$(bash -c "source '$project_root/hooks/workflow-lib.sh'; get_workflow_dir")

    # WORKFLOW_DIR未設定でworkflow-manager.shを呼び出し、
    # 実際に使われるディレクトリを確認するため一時的にワークフローを作成
    local wf_id
    wf_id=$(env -u WORKFLOW_DIR bash "$project_root/scripts/workflow-manager.sh" create "Test dir check")

    # get_workflow_dir()が返したパスにJSONが作成されているはず
    local state_file="$expected_dir/$wf_id.json"

    if [[ -f "$state_file" ]]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  PASS: WORKFLOW_DIR未設定時はget_workflow_dir()のパス($expected_dir)を使うこと"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  FAIL: WORKFLOW_DIR未設定時にget_workflow_dir()のパスが使われていない"
        echo "    Expected file: $state_file"
        echo "    get_workflow_dir() returned: $expected_dir"
    fi

    # クリーンアップ
    rm -f "$expected_dir/$wf_id.json"
}

# テスト実行
main() {
    echo "==================================="
    echo "Workflow Approval Tests"
    echo "==================================="

    setup

    test_create_9_phase_workflow
    test_codex_approval
    test_user_approval
    test_two_stage_approval
    test_cli_approve_third_argument
    test_is_approved_new_schema
    test_phase_transition_requires_approval
    test_phase_8_transition_requires_approval
    test_json_injection_resistance
    test_sequential_id_no_collision
    test_invalid_id_rejected
    test_tasks_commands
    test_default_workflow_dir_uses_get_workflow_dir

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
