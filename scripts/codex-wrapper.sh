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

    printf '%q ' "${filtered_args[@]}"
}

# リトライ付き実行 - macOS互換 timeout 実装
run_with_retry() {
    local cmd="$1"
    local retries=0

    while [[ $retries -lt $MAX_RETRIES ]]; do
        # バックグラウンドで実行
        bash -c "$cmd" 2>&1 &
        local pid=$!
        local elapsed=0
        local start_time=$(date +%s)
        
        # timeout管理ループ
        while [[ $elapsed -lt $CODEX_TIMEOUT ]]; do
            if ! kill -0 $pid 2>/dev/null; then
                # プロセス終了 - ステータスコード取得
                wait $pid 2>/dev/null
                return 0
            fi
            sleep 1
            local current_time=$(date +%s)
            elapsed=$((current_time - start_time))
        done
        
        # timeout 超過時はプロセス終了
        if kill -0 $pid 2>/dev/null; then
            kill $pid 2>/dev/null || true
            wait $pid 2>/dev/null || true
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

    # 環境変数でモデルと思考レベルを設定
    export CODEX_MODEL="$CODEX_MODEL"
    export CODEX_REASONING_EFFORT="$CODEX_REASONING"

    echo "Using model: $CODEX_MODEL, reasoning: $CODEX_REASONING_EFFORT" >&2

    local cmd="cd '$project_dir' && codex exec --full-auto '$safe_prompt'"

    if run_with_retry "$cmd"; then
        return 0
    else
        return 1
    fi
}

# Codex review 実行
codex_review() {
    local project_dir="${1:-.}"
    local review_type="${2:-uncommitted}"

    # 環境変数でモデルと思考レベルを設定
    export CODEX_MODEL="$CODEX_MODEL"
    export CODEX_REASONING_EFFORT="$CODEX_REASONING"

    echo "Using model: $CODEX_MODEL, reasoning: $CODEX_REASONING_EFFORT" >&2

    local cmd="cd '$project_dir' && codex review"

    if run_with_retry "$cmd"; then
        return 0
    else
        return 1
    fi
}

# 既存実装照合レビュー
codex_review_spec() {
    local project_dir="${1:-.}"
    local plan_content="$2"

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

    codex_exec "$project_dir" "$prompt"
}

# 要件カバレッジレビュー
codex_review_requirements() {
    local project_dir="${1:-.}"
    local plan_content="$2"
    local requirements="$3"

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

    codex_exec "$project_dir" "$prompt"
}

# フォールバック通知
notify_fallback() {
    cat <<EOF
{
    "fallback": true,
    "reason": "Codex CLI not available",
    "alternative": "fractal-dev-workflow:qa",
    "message": "Use qa agent as fallback for critical review (mandatory)"
}
EOF
}

# ヘルプ表示
show_help() {
    cat <<EOF
Usage: codex-wrapper.sh [command] [args...]

Commands:
  check                              Check if Codex CLI is available
  exec <dir> <prompt>                Execute Codex with prompt
  review <dir> [type]                Run code review
  review-spec <dir> <plan>           Run existing implementation review
  review-requirements <dir> <plan> <reqs>  Run requirements coverage review
  help                               Show this help

Environment Variables:
  CODEX_TIMEOUT           Timeout in seconds (default: 300)
  MAX_RETRIES             Max retry attempts (default: 2)
  CODEX_MODEL             Default model (default: codex-5.3)
  CODEX_REASONING         Default reasoning level (default: xhigh)
  CODEX_REASONING_EFFORT  Passed to codex CLI (set from CODEX_REASONING)

Examples:
  codex-wrapper.sh check
  codex-wrapper.sh exec . "Review this code"
  CODEX_REASONING=xhigh codex-wrapper.sh exec . "Review this code"
  codex-wrapper.sh review .
  codex-wrapper.sh review-spec . "\$(cat plan.md)"
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
            codex_review "${1:-.}" "${2:-uncommitted}"
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
            codex_review_spec "${1:-.}" "${2:-}"
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
            codex_review_requirements "${1:-.}" "${2:-}" "${3:-}"
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
