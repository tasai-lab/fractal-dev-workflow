#!/bin/bash
# workflow-manager.sh - ワークフロー状態管理
# 使用方法: workflow-manager.sh [command] [args...]

set -euo pipefail

WORKFLOW_DIR="${WORKFLOW_DIR:-$HOME/.claude/fractal-workflow}"

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
    local lock="$WORKFLOW_DIR/$workflow_id.lock"
    mkdir -p "$WORKFLOW_DIR"
    exec 200>"$lock"
    flock -n 200 || { echo "ERROR: Workflow $workflow_id is locked" >&2; exit 1; }
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

    # Phase 5への遷移: Phase 4の2段階承認が必要
    if [[ "$phase" -ge 5 ]] && [[ "$current_phase" -lt 5 ]]; then
        local p4_codex=$(echo "$current" | jq -r '.phases["4"].codexApprovedAt // empty')
        local p4_user=$(echo "$current" | jq -r '.phases["4"].userApprovedAt // empty')
        if [[ -z "$p4_codex" ]] || [[ -z "$p4_user" ]]; then
            echo "ERROR: Phase 4の承認が完了していません" >&2
            exit 1
        fi
    fi

    # Phase 7への遷移: Phase 6の2段階承認が必要
    if [[ "$phase" -ge 7 ]] && [[ "$current_phase" -lt 7 ]]; then
        local p6_codex=$(echo "$current" | jq -r '.phases["6"].codexApprovedAt // empty')
        local p6_user=$(echo "$current" | jq -r '.phases["6"].userApprovedAt // empty')
        if [[ -z "$p6_codex" ]] || [[ -z "$p6_user" ]]; then
            echo "ERROR: Phase 6の承認が完了していません" >&2
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
    local workflow_id="wf-$(date +%Y%m%d)-$(printf '%03d' $((RANDOM % 1000)))"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local initial_state
    initial_state=$(cat <<EOF
{
    "workflowId": "$workflow_id",
    "taskDescription": "$description",
    "status": "active",
    "currentPhase": 1,
    "phases": {
        "1": {"name": "質問", "status": "pending"},
        "2": {"name": "調査", "status": "pending"},
        "3": {"name": "設計", "status": "pending"},
        "4": {"name": "計画レビュー", "status": "pending"},
        "5": {"name": "実装", "status": "pending"},
        "6": {"name": "コードレビュー", "status": "pending"},
        "7": {"name": "テスト", "status": "pending"},
        "8": {"name": "運用設計", "status": "pending"}
    },
    "createdAt": "$timestamp"
}
EOF
)
    set_state "$workflow_id" "$initial_state"
    echo "$workflow_id"
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
    help|--help|-h) show_help ;;
    *)
        echo "Unknown command: $1" >&2
        show_help
        exit 1
        ;;
esac
