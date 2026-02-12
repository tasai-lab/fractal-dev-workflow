#!/bin/bash
# session-init.sh - セッション開始時の初期化

WORKFLOW_DIR="$HOME/.claude/fractal-workflow"

# ディレクトリ作成
mkdir -p "$WORKFLOW_DIR"

# アクティブなワークフローを確認
active_count=$(find "$WORKFLOW_DIR" -name "wf-*.json" -exec grep -l '"status": "active"' {} \; 2>/dev/null | wc -l)

if [[ $active_count -gt 0 ]]; then
    # アクティブなワークフローがある場合は情報を出力
    echo '{"status": "info", "message": "Active workflow found. Use /dev status to check."}'
else
    echo '{"status": "ok"}'
fi
