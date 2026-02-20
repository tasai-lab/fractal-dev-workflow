#!/bin/bash
# session-init.sh - セッション開始時の初期化

# stdin読み取り（フックプロトコル）
cat > /dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workflow-lib.sh"
WORKFLOW_DIR=$(get_workflow_dir)

# ディレクトリ作成
mkdir -p "$WORKFLOW_DIR"

# アクティブなワークフローを確認（jqで正確にフィルタリング）
active_wf=""
while IFS= read -r f; do
    if jq -e '.status == "active"' "$f" > /dev/null 2>&1; then
        active_wf="$f"
        break
    fi
done < <(find "$WORKFLOW_DIR" -name "wf-*.json" 2>/dev/null | head -10)

# コンテキスト文字列を構築
CONTEXT=""
if [[ -n "$active_wf" ]]; then
    current_phase=$(jq -r '.currentPhase // "unknown"' "$active_wf" 2>/dev/null)
    current_slice=$(jq -r '.phases["5"].currentSlice // empty' "$active_wf" 2>/dev/null)
    mode=$(jq -r '.mode // "unknown"' "$active_wf" 2>/dev/null)
    workflow_id=$(jq -r '.workflowId // "unknown"' "$active_wf" 2>/dev/null)

    # Phase名称マッピング（bash 3.x互換のためcase文使用）
    case "$current_phase" in
        1) phase_name="質問 + 要件定義" ;;
        2) phase_name="調査 + ドメイン整理" ;;
        3) phase_name="契約設計" ;;
        4) phase_name="Codex計画レビュー" ;;
        5) phase_name="実装" ;;
        6) phase_name="Chromeデバッグ" ;;
        7) phase_name="Codexコードレビュー" ;;
        8) phase_name="検証" ;;
        9) phase_name="運用設計" ;;
        *) phase_name="unknown" ;;
    esac

    NL=$'\n'
    CONTEXT="========================================"
    CONTEXT+="${NL}  Active Workflow Detected"
    CONTEXT+="${NL}  Workflow: $workflow_id"
    CONTEXT+="${NL}  Current: Phase $current_phase - $phase_name"
    if [[ "$current_phase" == "5" && -n "$current_slice" && "$current_slice" != "null" ]]; then
        case "$current_slice" in
            1) slice_name="最小動作版 (MVP)" ;;
            2) slice_name="エラーハンドリング" ;;
            3) slice_name="エッジケース" ;;
            *) slice_name="unknown" ;;
        esac
        CONTEXT+="${NL}  Slice: $current_slice - $slice_name"
    fi
    CONTEXT+="${NL}  Mode: $mode"
    CONTEXT+="${NL}========================================"
    CONTEXT+="${NL}Use /dev resume to continue or /dev status for details."
fi

# hookSpecificOutput形式で出力（コンテキストがある場合のみ）
if [[ -n "$CONTEXT" ]]; then
    jq -n --arg ctx "$CONTEXT" '{
      hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: $ctx
      }
    }'
fi
