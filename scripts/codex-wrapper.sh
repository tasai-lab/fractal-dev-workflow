#!/bin/bash
# codex-wrapper.sh - Codex CLI 安全呼び出しラッパー
# 使用方法: codex-wrapper.sh [check|exec|review|review-spec|review-requirements] [args...]

set -euo pipefail

# 設定
CODEX_TIMEOUT="${CODEX_TIMEOUT:-300}"
MAX_RETRIES="${MAX_RETRIES:-2}"
CODEX_MODEL="${CODEX_MODEL:-codex-5.3}"
CODEX_REASONING="${CODEX_REASONING:-xhigh}"
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

# コマンドライン引数からモデル・思考レベルを抽出
parse_options() {
    local args=("$@")
    local filtered_args=()

    for ((i=0; i<${#args[@]}; i++)); do
        case "${args[i]}" in
            --model)
                CODEX_MODEL="${args[i+1]}"
                ((i++))
                ;;
            --reasoning)
                CODEX_REASONING="${args[i+1]}"
                ((i++))
                ;;
            *)
                filtered_args+=("${args[i]}")
                ;;
        esac
    done

    echo "${filtered_args[@]}"
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
    cmd+=" --model '$CODEX_MODEL'"
    cmd+=" --reasoning '$CODEX_REASONING'"
    cmd+=" --skip-git-repo-check"
    cmd+=" --full-auto"
    cmd+=" --sandbox read-only"

    if [[ -n "$output_file" ]]; then
        cmd+=" -o '$output_file'"
    else
        cmd+=" -o '$result_file'"
    fi

    cmd+=" '$safe_prompt'"

    echo "Using model: $CODEX_MODEL, reasoning: $CODEX_REASONING" >&2

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

# 既存実装照合レビュー
codex_review_spec() {
    local project_dir="${1:-.}"
    local plan_content="$2"
    local output_file="${3:-}"

    local prompt="## 既存実装照合レビュー

以下の計画を批判的にレビューしてください。特に以下の観点で問題点を指摘してください:

1. **既存実装との矛盾**: 計画で「新規作成」と記載されているものが、実際には既に存在していないか
2. **コード参照の欠如**: 変更対象ファイルに具体的なコード参照（path:line）がないものはないか
3. **二重実装リスク**: 既存の共通コンポーネント/ユーティリティを再実装しようとしていないか
4. **設定の不一致**: 既存コードと異なる設定（AIモデル、API設定等）を使用しようとしていないか

計画内容:
$plan_content

レビュー形式:
## Staff Review
### Summary
[1段落の総評]

### Critical Issues (P0 - Must Fix)
1. [問題]: [理由] → [推奨修正]

### Serious Issues (P1 - Should Fix)
1. [問題]: [理由] → [推奨修正]

### Verdict
[APPROVED / NEEDS CHANGES]"

    codex_exec "$project_dir" "$prompt" "$output_file"
}

# 要件カバレッジレビュー
codex_review_requirements() {
    local project_dir="${1:-.}"
    local plan_content="$2"
    local requirements="$3"
    local output_file="${4:-}"

    local prompt="## 要件カバレッジレビュー

以下の計画が要件を満たしているか批判的にレビューしてください:

要件:
$requirements

計画内容:
$plan_content

レビュー観点:
1. **要件の抜け漏れ**: すべての要件が計画に含まれているか
2. **要件の曖昧さ**: 要件の解釈が曖昧なまま計画に反映されていないか
3. **テスト戦略と要件の対応**: 各要件に対応するテストが計画されているか
4. **スコープクリープ**: 要件にない機能が計画に含まれていないか

レビュー形式:
## Requirements Coverage Review

### Coverage Matrix
| Requirement | Covered? | Plan Reference | Test Planned? |
|-------------|----------|----------------|---------------|
| [req 1] | Yes/No/Partial | [section] | Yes/No |

### Missing Requirements
1. [requirement]: [what's missing]

### Ambiguous Requirements
1. [requirement]: [why ambiguous]

### Verdict
[APPROVED / NEEDS CHANGES]"

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
Usage: codex-wrapper.sh [command] [args...] [options]

Commands:
  check                                    Check if Codex CLI is available
  exec <dir> <prompt> [out]                Execute Codex with prompt
  review <dir> [type] [out]                Run code review
  review-spec <dir> <plan> [out]           Run existing implementation review
  review-requirements <dir> <plan> <reqs> [out]  Run requirements coverage review
  help                                     Show this help

Options:
  --model <model>       Codex model (default: codex-5.3)
  --reasoning <level>   Reasoning level: low/medium/high/xhigh (default: xhigh)

Environment:
  CODEX_TIMEOUT    Timeout in seconds (default: 300)
  MAX_RETRIES      Max retry attempts (default: 2)
  CODEX_MODEL      Default model (default: codex-5.3)
  CODEX_REASONING  Default reasoning level (default: xhigh)

Examples:
  codex-wrapper.sh check
  codex-wrapper.sh exec . "Review this code"
  codex-wrapper.sh exec . "Review this code" --model codex-5.3 --reasoning xhigh
  codex-wrapper.sh review . uncommitted output.txt
  codex-wrapper.sh review-spec . "\$(cat plan.md)" output.txt
  codex-wrapper.sh review-requirements . "\$(cat plan.md)" "\$(cat requirements.md)"
EOF
}

# メインディスパッチ
case "${1:-help}" in
    check)
        if check_codex; then
            echo "available (model: $CODEX_MODEL, reasoning: $CODEX_REASONING)"
            exit 0
        else
            echo "unavailable"
            exit 1
        fi
        ;;
    exec)
        shift
        args=$(parse_options "$@")
        eval "set -- $args"
        if check_codex; then
            codex_exec "${1:-.}" "${2:-}" "${3:-}"
        else
            notify_fallback
            exit 1
        fi
        ;;
    review)
        shift
        args=$(parse_options "$@")
        eval "set -- $args"
        if check_codex; then
            codex_review "${1:-.}" "${2:-uncommitted}" "${3:-}"
        else
            notify_fallback
            exit 1
        fi
        ;;
    review-spec)
        shift
        args=$(parse_options "$@")
        eval "set -- $args"
        if check_codex; then
            codex_review_spec "${1:-.}" "${2:-}" "${3:-}"
        else
            notify_fallback
            exit 1
        fi
        ;;
    review-requirements)
        shift
        args=$(parse_options "$@")
        eval "set -- $args"
        if check_codex; then
            codex_review_requirements "${1:-.}" "${2:-}" "${3:-}" "${4:-}"
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
