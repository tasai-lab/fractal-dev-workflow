---
description: マージ後タスクを実行
---

Invoke the fractal-dev-workflow:post-merge-execute skill to handle post-merge tasks.

The user wants to execute post-merge tasks. Use the skill to:
1. Search for task files in docs/post-merge-tasks/
2. Display incomplete tasks
3. Execute tasks after confirmation
4. Update completion status

## Usage
/post-merge [branch-name]

If branch-name is omitted, execute tasks for the last merged branch.

## Process
1. Locate task file for the specified or last merged branch
2. Parse and display incomplete tasks
3. Wait for user confirmation
4. Execute tasks sequentially
5. Update task status to completed
