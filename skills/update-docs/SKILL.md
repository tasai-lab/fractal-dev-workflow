---
name: update-docs
description: mainプッシュ前にドキュメント（CHANGELOG、フロー図）を最新に更新する時に使用
---

# Update Documentation

## Overview

mainブランチへのpush前に、プロジェクトドキュメントを最新の状態に更新する。

**Core principle:** コードの変更にはドキュメントの更新が伴う。

## The Process

### Step 1: 変更内容の収集

```bash
# 直近の変更を確認
git log --oneline -20
git diff main --stat
```

### Step 2: CHANGELOG.md の更新

以下の形式で `[Unreleased]` セクションを更新:

```markdown
## [Unreleased]

### Added
- [新機能]

### Changed
- [変更内容]

### Fixed
- [修正内容]

### Removed
- [削除内容]
```

**ルール:**
- Keep a Changelog 形式を維持
- 各エントリは具体的に（「改善」ではなく「Phase 4のレビュー自動遷移化」）
- カテゴリ: Added, Changed, Fixed, Deprecated, Removed, Security

### Step 3: フロードキュメントの更新

`docs/workflow-flow.md` が最新のワークフローを反映しているか確認。
変更がある場合はMermaid図を更新。

### Step 4: README.md の確認

特徴説明、フロー図、エージェント一覧が最新か確認。

## Completion Criteria

- [ ] CHANGELOG.md の [Unreleased] が最新
- [ ] docs/workflow-flow.md が最新のフローを反映
- [ ] README.md に矛盾がない
