#!/bin/bash
# check-docs.sh - ドキュメント更新チェック（git push前）
# Claude Code PreToolUse フックとして動作

set -euo pipefail

# 入力をJSONとして受け取る（Claude Codeがstdinで渡す）
INPUT=$(cat)

# Bashツール以外は無視
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
if [[ "$TOOL_NAME" != "Bash" ]]; then
    echo '{"status": "ok"}'
    exit 0
fi

# コマンドを取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# git push でないなら無視
if ! echo "$COMMAND" | grep -qE 'git\s+push'; then
    echo '{"status": "ok"}'
    exit 0
fi

# mainブランチへのpushか確認
if echo "$COMMAND" | grep -qE 'git\s+push.*\b(main|master|origin\s+main|origin\s+master)\b'; then
    IS_MAIN_PUSH=true
else
    # 引数なしのgit pushで現在のブランチがmainの場合
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]] && ! echo "$COMMAND" | grep -qE 'origin\s+\w+'; then
        IS_MAIN_PUSH=true
    else
        IS_MAIN_PUSH=false
    fi
fi

if [[ "$IS_MAIN_PUSH" != "true" ]]; then
    echo '{"status": "ok"}'
    exit 0
fi

# mainへのpush: ドキュメントチェック
WARNINGS=""

# 1. CHANGELOGが更新されているか
CHANGELOG_CHANGED=$(git diff main --name-only 2>/dev/null | grep -c "CHANGELOG.md" || true)
if [[ "$CHANGELOG_CHANGED" -eq 0 ]]; then
    # 直近のコミットでCHANGELOGが変更されているか
    CHANGELOG_IN_COMMITS=$(git log main..HEAD --name-only --format="" 2>/dev/null | grep -c "CHANGELOG.md" || true)
    if [[ "$CHANGELOG_IN_COMMITS" -eq 0 ]]; then
        WARNINGS="${WARNINGS}\n- CHANGELOG.md が更新されていません"
    fi
fi

# 2. docs/workflow-flow.md が存在するか
if [[ ! -f "docs/workflow-flow.md" ]]; then
    WARNINGS="${WARNINGS}\n- docs/workflow-flow.md が存在しません"
fi

# 警告がある場合
if [[ -n "$WARNINGS" ]]; then
    WARN_MSG=$(echo -e "$WARNINGS")
    echo "{\"status\": \"warn\", \"message\": \"mainへのpush前にドキュメントを確認してください:${WARN_MSG}\n\nドキュメント更新スキル: /update-docs\"}"
    exit 0
fi

echo '{"status": "ok", "message": "ドキュメントチェック OK"}'
exit 0
