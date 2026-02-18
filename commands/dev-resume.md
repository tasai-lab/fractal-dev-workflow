---
description: 中断されたワークフローを再開
---

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
