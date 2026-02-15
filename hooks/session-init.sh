#!/bin/bash
# session-init.sh - セッション開始時の初期化

WORKFLOW_DIR="$HOME/.claude/fractal-workflow"
GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
PROJECT_CLAUDE_MD="./CLAUDE.md"

# ディレクトリ作成
mkdir -p "$WORKFLOW_DIR"

# CLAUDE.md確認関数
check_claude_md() {
    local file_path="$1"
    local type="$2"

    if [[ ! -f "$file_path" ]]; then
        echo "\"$type\": {\"exists\": false}"
        return
    fi

    # 最初の5行を取得してサマリーとする（空行とコメントをスキップ）
    local summary=$(head -n 10 "$file_path" | grep -v '^#' | grep -v '^$' | head -n 3 | tr '\n' ' ' | sed 's/"/\\"/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ -z "$summary" ]]; then
        summary="(empty or comments only)"
    fi

    echo "\"$type\": {\"exists\": true, \"summary\": \"$summary\"}"
}

# アクティブなワークフローを確認
active_count=$(find "$WORKFLOW_DIR" -name "wf-*.json" -exec grep -l '"status": "active"' {} \; 2>/dev/null | wc -l)

# JSON出力を構築
global_md=$(check_claude_md "$GLOBAL_CLAUDE_MD" "global")
project_md=$(check_claude_md "$PROJECT_CLAUDE_MD" "project")

workflow_status="false"
status="ok"
message=""

if [[ $active_count -gt 0 ]]; then
    workflow_status="true"
    status="info"
    message=", \"message\": \"Active workflow found. Use /dev status to check.\""
fi

# JSON出力
echo "{\"status\": \"$status\"$message, \"claudeMd\": {$global_md, $project_md}, \"workflow\": {\"active\": $workflow_status}}"
