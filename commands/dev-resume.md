---
description: 中断されたワークフローを再開
---

再開時の手順:
1. wf-*.json を読み込む
2. Phase Banner Protocol に従いバナーを表示

```
========================================
  Phase {N}: {Phase名称}
  Workflow: {workflowId}
  Mode: {mode}
========================================
```

3. Phase 5の場合は Slice Banner も表示

```
----------------------------------------
  Phase 5 > Slice {N}: {Slice名称}
  Workflow: {workflowId}
----------------------------------------
```

4. 該当Phaseのスキルを起動

Read the workflow state file at ~/.claude/fractal-workflow/ and resume from the current phase.

Invoke the appropriate fractal-dev-workflow skill based on the current phase:
- Phase 1: fractal-dev-workflow:questioning
- Phase 2: fractal-dev-workflow:investigation
- Phase 3: fractal-dev-workflow:design
- Phase 4: fractal-dev-workflow:codex-review
- Phase 5: fractal-dev-workflow:implementation
- Phase 6: fractal-dev-workflow:chrome-debug
- Phase 7: fractal-dev-workflow:codex-review
- Phase 8: fractal-dev-workflow:verification
- Phase 9: fractal-dev-workflow:completion
