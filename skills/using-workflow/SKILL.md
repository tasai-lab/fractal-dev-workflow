---
name: using-workflow
description: 会話開始時に使用 - ワークフロースキルの検索・使用方法を確立
---

# Using Fractal Dev Workflow

## Overview

このプラグインの使用方法とスキルの呼び出し方を説明する。

## Available Commands

| Command | Description |
|---------|-------------|
| `/dev [task]` | Start new development workflow |
| `/dev resume` | Resume interrupted workflow |
| `/dev status` | Show current workflow state |
| `/dev cancel` | Cancel active workflow |

## The Nine Phases

| Phase | Name | Auto/Approval |
|-------|------|---------------|
| 1 | 質問 (Questioning) | Auto |
| 2 | 調査 (Investigation) | Auto |
| 3 | 契約設計 (Contract Design) | **User Approval Required** |
| 4 | Codex計画レビュー (Plan Review) | Auto (Codex承認のみ) |
| 5 | 実装 (Implementation) | Auto |
| 6 | Chromeデバッグ (Chrome Debug) | Auto |
| 7 | Codexコードレビュー (Code Review) | Auto (Codex承認のみ) |
| 8 | 検証 (Verification) | Auto |
| 9 | 運用設計 (Operations) | Auto |

## Skill Invocation

**IMPORTANT:** If any skill MIGHT apply, invoke it BEFORE taking action.

### Core Workflow Skills
- `dev-workflow` - Main orchestrator
- `questioning` - Phase 1
- `investigation` - Phase 2
- `design` - Phase 3
- `codex-review` - Phase 4 / Phase 7
- `implementation` - Phase 5
- `chrome-debug` - Phase 6
- `verification` - Phase 8
- `completion` - Phase 9

### Support Skills
- `failure-memory` - Learn from failures
- `parallel-implementation` - Parallel execution
- `context-circulation` - Commit-based context sharing

## Quick Start

1. Receive development task
2. Invoke `dev-workflow` skill
3. Follow phase progression
4. Wait for user approval at Phase 3 (Contract Design)
5. Phases 4 and 7 auto-transition after Codex review
5. Complete workflow

## Red Flags

If you're thinking:
- "Skip phases, it's simple" → Use full workflow
- "I know what to do" → Still use questioning phase
- "Just code it" → Plan first
- "Review is overkill" → External review catches more

## Integration with Other Plugins

This plugin works with:
- **superpowers** - TDD, debugging, verification skills
- **task-manager** - TaskCreate/TaskUpdate for tracking

## State Files

- Workflow state: `$(bash ~/.claude/plugins/local/fractal-dev-workflow/scripts/workflow-manager.sh get-dir)/{workflow-id}.json`
- Failure memory: `$(bash ~/.claude/plugins/local/fractal-dev-workflow/scripts/workflow-manager.sh get-dir)/failure-memory.json`
