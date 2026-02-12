#!/bin/bash
# codex-wrapper.sh - Codex CLI 安全呼び出しラッパー
# 使用方法: codex-wrapper.sh [check|exec|review] [args...]

set -euo pipefail

# 設定
CODEX_TIMEOUT="${CODEX_TIMEOUT:-300}"
MAX_RETRIES="${MAX_RETRIES:-2}"
SECRET_PATTERNS=(
    'ANTHROPIC_API_KEY'
    'OPENAI_API_KEY'
    'GITHUB_TOKEN'
    'AWS_SECRET'
    'password'
    'secret'
    'token'
    'credential'
    'api_key'
    'apikey'
)

# Codex CLI 利用可能性チェック
check_codex() {
    if ! command -v codex &>/dev/null; then
        return 1
    fi
    return 0
}

# シークレットフィルタ
filter_secrets() {
    local input="$1"
    local filtered="$input"
    for pattern in "${SECRET_PATTERNS[@]}"; do
        filtered=$(echo "$filtered" | sed -E "s/($pattern[[:space:]]*[:=][[:space:]]*)[^[:space:]\"\']*/\1[REDACTED]/gi")
    done
    echo "$filtered"
}

# 一時ディレクトリ作成
create_temp_dir() {
    mktemp -d "${TMPDIR:-/tmp}/codex-wrapper-XXXXXX"
}

# リトライ付き実行
run_with_retry() {
    local cmd="$1"
    local retries=0

    while [[ $retries -lt $MAX_RETRIES ]]; do
        if timeout "$CODEX_TIMEOUT" bash -c "$cmd" 2>&1; then
            return 0
        fi
        ((retries++))
        if [[ $retries -lt $MAX_RETRIES ]]; then
            echo "Retry $retries/$MAX_RETRIES..." >&2
            sleep 2
        fi
    done

    return 1
}

# Codex exec 実行
codex_exec() {
    local project_dir="${1:-.}"
    local prompt="$2"
    local output_file="${3:-}"

    local safe_prompt
    safe_prompt=$(filter_secrets "$prompt")
    local temp_dir
    temp_dir=$(create_temp_dir)
    local result_file="$temp_dir/result.txt"

    local cmd="codex exec"
    cmd+=" -C '$project_dir'"
    cmd+=" --skip-git-repo-check"
    cmd+=" --full-auto"
    cmd+=" --sandbox read-only"

    if [[ -n "$output_file" ]]; then
        cmd+=" -o '$output_file'"
    else
        cmd+=" -o '$result_file'"
    fi

    cmd+=" '$safe_prompt'"

    if run_with_retry "$cmd"; then
        if [[ -z "$output_file" ]] && [[ -f "$result_file" ]]; then
            cat "$result_file"
        fi
        rm -rf "$temp_dir"
        return 0
    else
        rm -rf "$temp_dir"
        return 1
    fi
}

# Codex review 実行
codex_review() {
    local project_dir="${1:-.}"
    local review_type="${2:-uncommitted}"
    local output_file="${3:-}"

    local prompt="以下の観点でコードをレビューしてください:
- コード品質と可読性
- セキュリティ（OWASP Top 10）
- パフォーマンス
- エラーハンドリング
- テストカバレッジ"

    codex_exec "$project_dir" "$prompt" "$output_file"
}

# フォールバック通知
notify_fallback() {
    cat <<EOF
{
    "fallback": true,
    "reason": "Codex CLI not available",
    "alternative": "staff-reviewer",
    "message": "Use staff-reviewer agent as fallback for critical review"
}
EOF
}

# ヘルプ表示
show_help() {
    cat <<EOF
Usage: codex-wrapper.sh [command] [args...]

Commands:
  check                       Check if Codex CLI is available
  exec <dir> <prompt> [out]   Execute Codex with prompt
  review <dir> [type] [out]   Run code review
  help                        Show this help

Environment:
  CODEX_TIMEOUT  Timeout in seconds (default: 300)
  MAX_RETRIES    Max retry attempts (default: 2)

Examples:
  codex-wrapper.sh check
  codex-wrapper.sh exec . "Review this code"
  codex-wrapper.sh review . uncommitted output.txt
EOF
}

# メインディスパッチ
case "${1:-help}" in
    check)
        if check_codex; then
            echo "available"
            exit 0
        else
            echo "unavailable"
            exit 1
        fi
        ;;
    exec)
        if check_codex; then
            codex_exec "${2:-.}" "${3:-}" "${4:-}"
        else
            notify_fallback
            exit 1
        fi
        ;;
    review)
        if check_codex; then
            codex_review "${2:-.}" "${3:-uncommitted}" "${4:-}"
        else
            notify_fallback
            exit 1
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1" >&2
        show_help
        exit 1
        ;;
esac
