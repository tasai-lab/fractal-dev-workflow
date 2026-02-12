#!/bin/bash
# check-approval.sh - 承認状態をチェックしてWrite/Editをブロック

WORKFLOW_DIR="$HOME/.claude/fractal-workflow"

# アクティブなワークフローを探す
find_active_workflow() {
    find "$WORKFLOW_DIR" -name "wf-*.json" -exec grep -l '"status": "active"' {} \; 2>/dev/null | head -1
}

active_wf=$(find_active_workflow)

# アクティブなワークフローがない場合は許可
if [[ -z "$active_wf" ]]; then
    echo '{"status": "ok"}'
    exit 0
fi

# ワークフロー状態を読み取り
state=$(cat "$active_wf")
current_phase=$(echo "$state" | jq -r '.currentPhase // 0')

# Phase 5（実装）未満で Write/Edit を試みている場合
if [[ $current_phase -lt 5 ]]; then
    phase_name=$(echo "$state" | jq -r ".phases[\"$current_phase\"].name // \"unknown\"")

    # 計画フェーズ（Phase 3）が承認されていない場合はブロック
    if [[ $current_phase -le 3 ]]; then
        phase3_approved=$(echo "$state" | jq -r '.phases["3"].approvedAt // empty')
        if [[ -z "$phase3_approved" ]]; then
            cat <<EOF
{
    "status": "error",
    "message": "Implementation blocked: Planning phase (Phase 3) not yet approved. Current phase: $current_phase ($phase_name). Complete phases 1-3 and get approval before implementing."
}
EOF
            exit 1
        fi
    fi
fi

# Phase 5（実装）にいるが、実装承認フェーズでない場合も警告
# ただし、ブロックはしない（実装中はWrite/Edit必要）
echo '{"status": "ok"}'
