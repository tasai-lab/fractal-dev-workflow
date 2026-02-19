#!/bin/bash
# workflow-lib.sh - ワークフロー共通関数

# ワークツリー固有のワークフローディレクトリを返す
get_workflow_dir() {
    local worktree_root
    worktree_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    local worktree_hash
    worktree_hash=$(printf '%s' "$worktree_root" | md5 -q 2>/dev/null || printf '%s' "$worktree_root" | md5sum | cut -c1-12)
    worktree_hash="${worktree_hash:0:12}"
    echo "$HOME/.claude/fractal-workflow/$worktree_hash"
}

# フック共通ログ関数
HOOK_LOG_FILE="/tmp/fractal-hooks.log"

hook_log() {
    local hook_name="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$hook_name] $message" >> "$HOOK_LOG_FILE"
}

hook_error() {
    local hook_name="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$hook_name] ERROR: $message" >> "$HOOK_LOG_FILE"
}
