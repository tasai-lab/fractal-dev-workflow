#!/bin/bash
# workflow-manager.sh - ワークフロー状態管理
# 使用方法: workflow-manager.sh [command] [args...]

set -euo pipefail

# workflow-lib.sh をsource（worktreeごとのパス解決に使用）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="$SCRIPT_DIR/../hooks/workflow-lib.sh"
if [[ -f "$LIB_PATH" ]]; then
    source "$LIB_PATH"
    WORKFLOW_DIR="${WORKFLOW_DIR:-$(get_workflow_dir)}"
else
    GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null)
    WORKFLOW_DIR="${WORKFLOW_DIR:-${GIT_COMMON:-.git}/fractal-workflow}"
fi

mkdir -p "$WORKFLOW_DIR"

# workflow_id のフォーマット検証
validate_workflow_id() {
    local workflow_id="$1"
    if ! [[ "$workflow_id" =~ ^wf-[0-9]{8}-[0-9]{3}$ ]]; then
        echo "ERROR: Invalid workflow_id format: $workflow_id" >&2
        echo "Expected format: wf-YYYYMMDD-NNN" >&2
        exit 1
    fi
}

# ファイルロック取得
acquire_lock() {
    local workflow_id="$1"
    local lock_dir="$WORKFLOW_DIR/$workflow_id.lock"
    mkdir -p "$WORKFLOW_DIR"

    # macOS互換: mkdirをアトミックロックとして使用
    local max_attempts=10
    local attempt=0
    while ! mkdir "$lock_dir" 2>/dev/null; do
        attempt=$((attempt + 1))
        if [[ $attempt -ge $max_attempts ]]; then
            echo "ERROR: Workflow $workflow_id is locked" >&2
            exit 1
        fi
        sleep 0.1
    done

    # クリーンアップ用のトラップ設定
    trap "rm -rf '$lock_dir'" EXIT
}

# ワークフロー状態読み取り
get_state() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local state_file="$WORKFLOW_DIR/$workflow_id.json"
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
    else
        echo "{}"
    fi
}

# ワークフロー状態書き込み
set_state() {
    local workflow_id="$1"
    local new_state="$2"
    local state_file="$WORKFLOW_DIR/$workflow_id.json"
    mkdir -p "$WORKFLOW_DIR"
    echo "$new_state" > "$state_file"
}

# 現在フェーズ取得
get_phase() {
    local workflow_id="$1"
    get_state "$workflow_id" | jq -r '.currentPhase // 0'
}

# フェーズ更新
set_phase() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local phase="$2"

    acquire_lock "$workflow_id"
    local current=$(get_state "$workflow_id")
    local current_phase=$(echo "$current" | jq -r '.currentPhase // 0')

    # Phase 5への遷移: Phase 4のCodex承認が必要（自動遷移のためユーザー承認不要）
    if [[ "$phase" -ge 5 ]] && [[ "$current_phase" -lt 5 ]]; then
        local p4_codex=$(echo "$current" | jq -r '.phases["4"].codexApprovedAt // empty')
        if [[ -z "$p4_codex" ]]; then
            echo "ERROR: Phase 4のCodex承認が完了していません" >&2
            exit 1
        fi
    fi

    # Phase 8への遷移: Phase 7のCodex承認が必要（自動遷移のためユーザー承認不要）
    if [[ "$phase" -ge 8 ]] && [[ "$current_phase" -lt 8 ]]; then
        local p7_codex=$(echo "$current" | jq -r '.phases["7"].codexApprovedAt // empty')
        if [[ -z "$p7_codex" ]]; then
            echo "ERROR: Phase 7のCodex承認が完了していません" >&2
            exit 1
        fi
    fi

    local updated=$(echo "$current" | jq --arg p "$phase" '.currentPhase = ($p | tonumber)')
    set_state "$workflow_id" "$updated"
}

# 承認状態確認
is_approved() {
    local workflow_id="$1"
    local phase="$2"
    local state=$(get_state "$workflow_id")
    local approved=$(echo "$state" | jq -r ".phases[\"$phase\"].userApprovedAt // empty")
    [[ -n "$approved" ]]
}

# 承認を記録（タイプ: codex または user）
approve() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local phase="$2"
    local approver="${3:-user}"  # デフォルトはuser

    acquire_lock "$workflow_id"
    local state=$(get_state "$workflow_id")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ "$approver" == "codex" ]]; then
        local updated=$(echo "$state" | jq --arg p "$phase" --arg t "$timestamp" \
            '.phases[$p].codexApprovedAt = $t')
    else
        local updated=$(echo "$state" | jq --arg p "$phase" --arg t "$timestamp" \
            '.phases[$p].userApprovedAt = $t | .phases[$p].status = "completed"')
    fi

    set_state "$workflow_id" "$updated"
}

# 後方互換性のため、record_approval は approve のエイリアスとする
record_approval() {
    approve "$@"
}

# 新規ワークフロー作成
create_workflow() {
    local description="${1:-New workflow}"
    local today="$(date +%Y%m%d)"
    # 既存IDの最大連番+1（途中削除があっても衝突しない）
    local max_seq=0
    while IFS= read -r f; do
        local fname
        fname=$(basename "$f" .json)
        local seq="${fname##*-}"
        local n=$((10#${seq}))
        [[ $n -gt $max_seq ]] && max_seq=$n
    done < <(find "$WORKFLOW_DIR" -name "wf-${today}-*.json" 2>/dev/null)
    local seq_num=$((max_seq + 1))
    local workflow_id="wf-${today}-$(printf '%03d' $seq_num)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local state_file="$WORKFLOW_DIR/$workflow_id.json"

    local worktree_base="${FRACTAL_WORKTREE_BASE:-$HOME/code/fractal-worktrees}"
    local worktree_path="$worktree_base/workflow-$workflow_id"
    local worktree_branch="workflow/$workflow_id"

    jq -n \
      --arg wfid "$workflow_id" \
      --arg desc "$description" \
      --arg ts "$timestamp" \
      --arg mode "" \
      --arg wtp "$worktree_path" \
      --arg wtb "$worktree_branch" \
      '{
        workflowId: $wfid,
        taskDescription: $desc,
        status: "active",
        currentPhase: 1,
        worktreePath: $wtp,
        worktreeBranch: $wtb,
        phases: {
          "1": {name: "質問", status: "pending"},
          "2": {name: "調査", status: "pending"},
          "3": {name: "設計", status: "pending"},
          "4": {name: "計画レビュー", status: "pending"},
          "5": {name: "実装", status: "pending", currentSlice: null, slices: {}},
          "6": {name: "Chromeデバッグ", status: "pending"},
          "7": {name: "コードレビュー", status: "pending"},
          "8": {name: "テスト", status: "pending"},
          "9": {name: "運用設計", status: "pending"}
        },
        createdAt: $ts,
        mode: $mode
      }' > "$state_file"

    echo "$workflow_id"
}

# タスク一覧取得
tasks() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local state=$(get_state "$workflow_id")
    echo "$state" | jq '{
      workflowId: .workflowId,
      currentPhase: .currentPhase,
      tasks: (.tasks // []),
      phases: [.phases | to_entries[] | {phase: .key, name: .value.name, status: .value.status}]
    }'
}

# タスク追加
add_task() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local task_id="$2"
    local subject="$3"
    local phase="${4:-}"

    acquire_lock "$workflow_id"
    local state=$(get_state "$workflow_id")
    local updated=$(echo "$state" | jq \
      --arg tid "$task_id" \
      --arg subj "$subject" \
      --arg ph "$phase" \
      '.tasks = (.tasks // []) + [{taskId: $tid, subject: $subj, phase: ($ph | if . == "" then null else . end), status: "pending"}]')
    set_state "$workflow_id" "$updated"
}

# タスク状態更新
update_task() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local task_id="$2"
    local status="$3"

    acquire_lock "$workflow_id"
    local state=$(get_state "$workflow_id")
    local updated=$(echo "$state" | jq \
      --arg tid "$task_id" \
      --arg st "$status" \
      '(.tasks // []) |= map(if .taskId == $tid then .status = $st else . end)')
    set_state "$workflow_id" "$updated"
}

# Slice追加（Phase 5のslicesフィールドに登録）
add_slice() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local slice_num="$2"
    local name="$3"
    local task_id="${4:-}"

    acquire_lock "$workflow_id"
    local state=$(get_state "$workflow_id")
    local updated=$(echo "$state" | jq \
      --arg sn "$slice_num" \
      --arg nm "$name" \
      --arg tid "$task_id" \
      '.phases["5"].slices[$sn] = {status: "pending", name: $nm, taskId: (if $tid == "" then null else $tid end)}')
    set_state "$workflow_id" "$updated"
}

# Slice状態更新
update_slice() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local slice_num="$2"
    local status="$3"

    acquire_lock "$workflow_id"
    local state=$(get_state "$workflow_id")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local updated
    if [[ "$status" == "in_progress" ]]; then
        updated=$(echo "$state" | jq \
          --arg sn "$slice_num" --arg st "$status" --arg ts "$timestamp" \
          '.phases["5"].currentSlice = ($sn | tonumber) | .phases["5"].slices[$sn].status = $st | .phases["5"].slices[$sn].startedAt = $ts')
    elif [[ "$status" == "completed" ]]; then
        updated=$(echo "$state" | jq \
          --arg sn "$slice_num" --arg st "$status" --arg ts "$timestamp" \
          '.phases["5"].slices[$sn].status = $st | .phases["5"].slices[$sn].completedAt = $ts')
    else
        updated=$(echo "$state" | jq \
          --arg sn "$slice_num" --arg st "$status" \
          '.phases["5"].slices[$sn].status = $st')
    fi
    set_state "$workflow_id" "$updated"
}

# Slice一覧表示
list_slices() {
    local workflow_id="$1"
    validate_workflow_id "$workflow_id"
    local state=$(get_state "$workflow_id")
    echo "$state" | jq '{
      workflowId: .workflowId,
      currentSlice: .phases["5"].currentSlice,
      slices: (.phases["5"].slices // {})
    }'
}

# アクティブなワークフロー一覧
list_active() {
    find "$WORKFLOW_DIR" -name "wf-*.json" -exec basename {} .json \; 2>/dev/null | while read -r wf; do
        local status=$(get_state "$wf" | jq -r '.status // "unknown"')
        if [[ "$status" == "active" ]]; then
            echo "$wf"
        fi
    done
}

# ヘルプ表示
show_help() {
    cat <<EOF
Usage: workflow-manager.sh [command] [args...]

Commands:
  create <description>      Create new workflow
  get <workflow_id>         Get workflow state
  phase <workflow_id>       Get current phase number
  set-phase <id> <phase>    Set current phase
  is-approved <id> <phase>  Check if phase is approved
  approve <id> <phase>      Record phase approval
  lock <workflow_id>        Acquire workflow lock
  list                      List active workflows
  get-dir                    Get workflow directory path (worktree-scoped)
  tasks <id>                 List tasks in workflow
  add-task <id> <taskId> <subject> [phase]  Add task to workflow
  update-task <id> <taskId> <status>       Update task status
  add-slice <id> <slice_num> <name> [taskId]  Add slice to Phase 5
  update-slice <id> <slice_num> <status>      Update slice status (pending/in_progress/completed)
  slices <id>                                 List slices in Phase 5
  help                      Show this help

Examples:
  workflow-manager.sh create "Implement feature X"
  workflow-manager.sh get wf-20260212-001
  workflow-manager.sh approve wf-20260212-001 3
EOF
}

# メインディスパッチ
case "${1:-help}" in
    create) create_workflow "${2:-}" ;;
    get) get_state "${2:-}" ;;
    phase) get_phase "${2:-}" ;;
    set-phase) set_phase "${2:-}" "${3:-}" ;;
    is-approved) is_approved "${2:-}" "${3:-}" && echo "true" || echo "false" ;;
    approve) approve "${2:-}" "${3:-}" "${4:-user}" ;;
    lock) acquire_lock "${2:-}" ;;
    list) list_active ;;
    get-dir) echo "$WORKFLOW_DIR" ;;
    tasks) tasks "${2:-}" ;;
    add-task) add_task "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
    update-task) update_task "${2:-}" "${3:-}" "${4:-}" ;;
    add-slice) add_slice "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
    update-slice) update_slice "${2:-}" "${3:-}" "${4:-}" ;;
    slices) list_slices "${2:-}" ;;
    help|--help|-h) show_help ;;
    *)
        echo "Unknown command: $1" >&2
        show_help
        exit 1
        ;;
esac
