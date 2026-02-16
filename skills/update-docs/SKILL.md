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

### Step 4: バージョン更新

変更の規模に応じてバージョンを更新:

| 変更規模 | バージョン | 例 |
|---------|----------|---|
| 破壊的変更 | メジャー (x.0.0) | ワークフロー構造の変更 |
| 機能追加・大きな改善 | マイナー (0.x.0) | 新スキル追加、フロー変更 |
| バグ修正・軽微な変更 | パッチ (0.0.x) | typo修正、文言変更 |

**更新対象ファイル:**
1. `.claude-plugin/plugin.json` の `version` フィールド
2. `CHANGELOG.md` の `[Unreleased]` → `[x.y.z] - YYYY-MM-DD`
3. シンボリックリンクのバージョンディレクトリ名

```bash
# バージョン更新例
NEW_VERSION="0.5.0"

# 1. plugin.json更新
# Edit tool で version フィールドを更新

# 2. CHANGELOG.md のUnreleasedをバージョン固定
# Edit tool で [Unreleased] → [0.5.0] - 2026-MM-DD に変更
# 新しい空の [Unreleased] セクションを先頭に追加

# 3. シンボリックリンク更新
rm -rf ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow
mkdir -p ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow
ln -s /Users/t.asai/code/fractal-dev-workflow ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow/$NEW_VERSION
```

### Step 5: README.md の確認

特徴説明、フロー図、エージェント一覧が最新か確認。

## Completion Criteria

- [ ] CHANGELOG.md の [Unreleased] が最新
- [ ] docs/workflow-flow.md が最新のフローを反映
- [ ] README.md に矛盾がない
- [ ] バージョンが更新されている (.claude-plugin/plugin.json)
- [ ] シンボリックリンクが新バージョンを指している
