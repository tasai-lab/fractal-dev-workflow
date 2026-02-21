#!/bin/bash
# workflow-lib.sh - ワークフロー共通関数

# リポジトリ共通のワークフローディレクトリを返す（ワークツリー間で共有）
# git-common-dir は主リポジトリ・ワークツリーどちらからでも同じ .git を返す
get_workflow_dir() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ -n "$git_common_dir" ]]; then
        # 相対パスを絶対パスに変換
        local abs_dir
        abs_dir=$(cd "$git_common_dir" 2>/dev/null && pwd) || {
            echo "$(pwd)/.git/fractal-workflow"
            return
        }
        echo "$abs_dir/fractal-workflow"
    else
        echo "$(pwd)/.git/fractal-workflow"
    fi
}

# ブランチ名からワークフローJSONを解決する
# workflow/{workflowId} ブランチ → wf-*.json を逆引き
find_workflow_by_branch() {
    local workflow_dir="${1:-$(get_workflow_dir)}"
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
    if [[ "$current_branch" =~ ^workflow/(wf-[0-9]{8}-[0-9]{3})$ ]]; then
        local wf_file="$workflow_dir/${BASH_REMATCH[1]}.json"
        if [[ -f "$wf_file" ]]; then
            echo "$wf_file"
            return
        fi
    fi
    echo ""
}

# ブランチベース優先でアクティブワークフローを解決する共通関数
find_active_workflow() {
    local workflow_dir="${1:-$(get_workflow_dir)}"
    # 第1優先: ブランチベース解決
    local branch_wf
    branch_wf=$(find_workflow_by_branch "$workflow_dir")
    if [[ -n "$branch_wf" ]]; then
        if jq -e '.status == "active"' "$branch_wf" > /dev/null 2>&1; then
            echo "$branch_wf"
            return
        fi
    fi
    # 第2優先: 従来方式（jqで正確にフィルタ、最新優先）
    while IFS= read -r f; do
        if jq -e '.status == "active"' "$f" > /dev/null 2>&1; then
            echo "$f"
            return
        fi
    done < <(find "$workflow_dir" -name "wf-*.json" 2>/dev/null | sort -r | head -10)
    echo ""
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

# チームメンバー判定関数
# エージェントチーム（TeamCreate）のチームメンバーとして動作しているかを判定する
# 戻り値: 0=チームメンバー, 1=非チームメンバー（単独セッション）
#
# Claude Code がチームメンバーセッションに設定する可能性のある環境変数をチェックする
# 環境変数が未設定の場合はフォールバックとしてマーカーファイルを確認する
is_team_member() {
    # 第1層: Claude Code 環境変数チェック
    # TeamCreate で起動されたチームメンバーセッションにはこれらの環境変数が設定される
    if [[ -n "${CLAUDE_CODE_TEAM_NAME:-}" ]]; then
        return 0
    fi
    if [[ -n "${CLAUDE_CODE_AGENT_NAME:-}" ]]; then
        return 0
    fi
    if [[ -n "${CLAUDE_CODE_PARENT_SESSION_ID:-}" ]]; then
        return 0
    fi

    # 第2層: マーカーファイルチェック（環境変数が利用できない場合のフォールバック）
    # SubagentStart フックまたは外部から登録されたセッションIDを確認する
    local marker_dir="/tmp/fractal-team-sessions"
    if [[ -d "$marker_dir" ]]; then
        # 現在のプロセスIDをもとにマーカーを確認（セッションID不明の場合の代替）
        # $$ はシェルのPID、$PPID は親プロセスID
        if [[ -f "$marker_dir/$$" ]] || [[ -f "$marker_dir/$PPID" ]]; then
            return 0
        fi
    fi

    return 1  # 非チームメンバー（通常の単独セッション）
}
