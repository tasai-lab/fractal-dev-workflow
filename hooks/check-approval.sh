#!/bin/bash
# check-approval.sh - 承認状態をチェックしてWrite/Editをブロック

# stdinからフック入力を読み取る（未使用だが消費必須）
cat > /dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workflow-lib.sh"

# チームメンバーの場合はPhaseゲートをバイパス
# TeamCreate で起動されたチームメンバーはリーダーの管理下で動作するため、
# 個別のPhase承認チェックは不要
if is_team_member; then
    hook_log "check-approval" "SKIP: team member detected (team_name=${CLAUDE_CODE_TEAM_NAME:-} agent=${CLAUDE_CODE_AGENT_NAME:-}), bypassing phase gate"
    exit 0
fi

WORKFLOW_DIR=$(get_workflow_dir)

# アクティブなワークフローを探す
active_wf=$(find_active_workflow "$WORKFLOW_DIR")

# アクティブなワークフローがない場合は許可
if [[ -z "$active_wf" ]]; then
    exit 0
fi

# ワークフロー状態を読み取り
state=$(cat "$active_wf")
current_phase=$(echo "$state" | jq -r '.currentPhase // 0 | tonumber' 2>/dev/null || echo "")

# currentPhase の型チェック
if ! [[ "$current_phase" =~ ^[0-9]+$ ]]; then
    jq -n --arg reason "Invalid currentPhase value in workflow state" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
fi

# Phase 5（実装）未満で Write/Edit を試みている場合
if [[ $current_phase -lt 5 ]]; then
    phase_name=$(echo "$state" | jq -r ".phases[\"$current_phase\"].name // \"unknown\"")

    # 設計フェーズ（Phase 3）が承認されていない場合はブロック
    if [[ $current_phase -le 3 ]]; then
        phase3_approved=$(echo "$state" | jq -r '.phases["3"].userApprovedAt // empty')
        if [[ -z "$phase3_approved" ]]; then
            jq -n --arg reason "Implementation blocked: Design phase (Phase 3) not yet approved. Current phase: $current_phase ($phase_name). Complete phases 1-3 and get approval before implementing." '{
              hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: $reason
              }
            }'
            exit 0
        fi
    fi

    # Phase 4（計画レビュー）のCodex承認チェック（自動遷移のためユーザー承認不要）
    if [[ $current_phase -eq 4 ]]; then
        phase4_codex=$(echo "$state" | jq --arg p "4" -r '.phases[$p].codexApprovedAt // empty')
        if [[ -z "$phase4_codex" ]]; then
            jq -n --arg reason "Implementation blocked: Phase 4 (計画レビュー) のCodex承認が必要です。'bash scripts/workflow-manager.sh approve {id} 4 codex' で承認してください。" '{
              hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: $reason
              }
            }'
            exit 0
        fi
    fi
fi

# Phase 8以降は Phase 7（コードレビュー）のCodex承認が必要（自動遷移のためユーザー承認不要）
if [[ $current_phase -ge 8 ]]; then
    phase7_codex=$(echo "$state" | jq --arg p "7" -r '.phases[$p].codexApprovedAt // empty')
    if [[ -z "$phase7_codex" ]]; then
        jq -n --arg reason "Implementation blocked: Phase 7 (コードレビュー) のCodex承認が必要です。'bash scripts/workflow-manager.sh approve {id} 7 codex' で承認してください。" '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
          }
        }'
        exit 0
    fi
fi

# Phase 5（実装）にいるが、実装承認フェーズでない場合も警告
# ただし、ブロックはしない（実装中はWrite/Edit必要）
exit 0
