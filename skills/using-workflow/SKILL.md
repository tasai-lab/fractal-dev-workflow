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

## The Six Phases

| Phase | Name | Auto/Approval |
|-------|------|---------------|
| 1 | 質問 (Questioning) | Auto |
| 2 | 調査 (Investigation) | Auto |
| 3 | 計画 (Planning) | **Approval Required** |
| 4 | 批判的レビュー (Critical Review) | Auto |
| 5 | 実装 (Implementation) | **Approval Required** |
| 6 | 完了 (Completion) | - |

## Skill Invocation

**IMPORTANT:** If any skill MIGHT apply, invoke it BEFORE taking action.

### Core Workflow Skills
- `dev-workflow` - Main orchestrator
- `questioning` - Phase 1
- `investigation` - Phase 2
- `planning` - Phase 3
- `codex-review` - Phase 4
- `implementation` - Phase 5

### Support Skills
- `failure-memory` - Learn from failures
- `parallel-implementation` - Parallel execution
- `context-circulation` - Commit-based context sharing

## Quick Start

1. Receive development task
2. Invoke `dev-workflow` skill
3. Follow phase progression
4. Wait for approvals at Phases 3 and 5
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

- Workflow state: `~/.claude/fractal-workflow/{workflow-id}.json`
- Failure memory: `~/.claude/fractal-workflow/failure-memory.json`
