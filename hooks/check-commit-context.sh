#!/bin/bash
# check-commit-context.sh - PostToolUse hook
# git commit完了を検出し、コンテキストドキュメント更新を指示する

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workflow-lib.sh" 2>/dev/null || true
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Bash以外は無視
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# git commitコマンドでなければ無視
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
    exit 0
fi

# git commit --amend（コンテキストドキュメント追加コミット）は無視してループ防止
if echo "$COMMAND" | grep -qE -- '--amend'; then
    exit 0
fi

# コンテキストドキュメント自体のコミット（"context-doc"を含む）も無視
if echo "$COMMAND" | grep -qE 'context-doc|コンテキストドキュメント'; then
    exit 0
fi

INSTRUCTION="[Context Document Update Required]

コミットが検出されました。サブエージェントでコンテキストドキュメントを更新してください:

Task(subagent_type=\"general-purpose\", model=\"sonnet\"):
  ## コンテキストドキュメント更新

  ### 手順
  1. git log --oneline -5 で最新コミットを確認
  2. git diff HEAD~1..HEAD --stat で変更ファイルを確認
  3. docs/context/CONTEXT.md を読む（存在しなければ新規作成）
  4. 以下のセクションを更新:
     - 現在の状態（Phase、進行中タスク）
     - 実装経緯テーブルに最新コミットを追加
     - 重要な決定事項（あれば追加）
     - ミスと教訓（あれば追加）
     - ユーザーとの対話要約（重要な指示があれば追加）
  5. ファイルを書き込む（docs/context/CONTEXT.md）
  6. git add docs/context/CONTEXT.md && git commit -m \"docs(context): コンテキストドキュメント更新\""

jq -n --arg ctx "$INSTRUCTION" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
