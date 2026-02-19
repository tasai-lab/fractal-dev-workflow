#!/bin/bash
# session-init.sh - セッション開始時の初期化

# stdin読み取り（フックプロトコル）
cat > /dev/null

WORKFLOW_DIR="$HOME/.claude/fractal-workflow"

# ディレクトリ作成
mkdir -p "$WORKFLOW_DIR"

# アクティブなワークフローを確認
active_wf=$(find "$WORKFLOW_DIR" -name "wf-*.json" -exec grep -l '"status": "active"' {} \; 2>/dev/null | head -1)

# コンテキスト文字列を構築
CONTEXT=""
if [[ -n "$active_wf" ]]; then
    CONTEXT="Active workflow found. Use /dev status to check current state."
fi

# hookSpecificOutput形式で出力
jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
