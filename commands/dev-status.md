---
description: 現在のワークフロー状態を表示
---

Read the workflow state file at ~/.claude/fractal-workflow/ and display the current status:
- Current phase
- Phase completion status
- Approval status for phases 4 and 7 (2-stage: Codex + User)

ステータス表示時は Phase Banner Protocol に従い、以下の形式で出力すること:

```
========================================
  Phase {N}: {Phase名称}
  Workflow: {workflowId}
  Mode: {mode}
========================================
```

Phase 5の場合はSlice情報も追加:

```
----------------------------------------
  Phase 5 > Slice {N}: {Slice名称}
  Workflow: {workflowId}
----------------------------------------
```

各Phaseの完了状態一覧も表示すること。
