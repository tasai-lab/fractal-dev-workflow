#!/bin/bash
# check-approval.sh - 承認状態をチェックしてWrite/Editをブロック

# stdinからフック入力を読み取る（未使用だが消費必須）
cat > /dev/null

WORKFLOW_DIR="$HOME/.claude/fractal-workflow"

# アクティブなワークフローを探す
find_active_workflow() {
    find "$WORKFLOW_DIR" -name "wf-*.json" -exec grep -l '"status": "active"' {} \; 2>/dev/null | head -1
}

active_wf=$(find_active_workflow)

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

    # Phase 4（計画レビュー）の2段階承認チェック
    if [[ $current_phase -eq 4 ]]; then
        phase4_codex=$(echo "$state" | jq --arg p "4" -r '.phases[$p].codexApprovedAt // empty')
        phase4_user=$(echo "$state" | jq --arg p "4" -r '.phases[$p].userApprovedAt // empty')
        if [[ -z "$phase4_codex" ]] || [[ -z "$phase4_user" ]]; then
            codex_status=$(if [[ -n "$phase4_codex" ]]; then echo "approved"; else echo "pending"; fi)
            user_status=$(if [[ -n "$phase4_user" ]]; then echo "approved"; else echo "pending"; fi)
            jq -n --arg reason "Implementation blocked: Phase 4 (計画レビュー) のCodex承認とユーザー承認が必要です。Current approvals - Codex: $codex_status, User: $user_status" '{
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

# Phase 8以降は Phase 7（コードレビュー）の2段階承認が必要
if [[ $current_phase -ge 8 ]]; then
    phase7_codex=$(echo "$state" | jq --arg p "7" -r '.phases[$p].codexApprovedAt // empty')
    phase7_user=$(echo "$state" | jq --arg p "7" -r '.phases[$p].userApprovedAt // empty')
    if [[ -z "$phase7_codex" ]] || [[ -z "$phase7_user" ]]; then
        codex_status=$(if [[ -n "$phase7_codex" ]]; then echo "approved"; else echo "pending"; fi)
        user_status=$(if [[ -n "$phase7_user" ]]; then echo "approved"; else echo "pending"; fi)
        jq -n --arg reason "Implementation blocked: Phase 7 (コードレビュー) のCodex承認とユーザー承認が必要です。Current approvals - Codex: $codex_status, User: $user_status" '{
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
