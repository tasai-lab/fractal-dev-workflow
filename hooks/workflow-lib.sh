#!/bin/bash
# workflow-lib.sh - ワークフロー共通関数

# リポジトリ共通のワークフローディレクトリを返す（ワークツリー間で共有）
# git-common-dir は主リポジトリ・ワークツリーどちらからでも同じ .git を返す
get_workflow_dir() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ -n "$git_common_dir" ]]; then
        # 相対パスを絶対パスに変換
        echo "$(cd "$git_common_dir" && pwd)/fractal-workflow"
    else
        echo "$(pwd)/.git/fractal-workflow"
    fi
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
