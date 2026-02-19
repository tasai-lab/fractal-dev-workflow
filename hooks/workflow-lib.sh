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
