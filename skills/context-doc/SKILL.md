---
name: context-doc
description: コミット毎にサブエージェントでコンテキストドキュメントを自動生成・更新し、compact後の再注入を可能にする
---

# Context Document Generator

## Overview

git commit 毎にサブエージェント（sonnet）がコンテキストドキュメントを自動更新する。
ドキュメントは `docs/context/CONTEXT.md` に保存され、compact 後のコンテキスト再注入に使用する。

**トリガー:** PostToolUse hook (check-commit-context.sh) が git commit を検出
**実行者:** サブエージェント (general-purpose, sonnet)
**保存先:** docs/context/CONTEXT.md (git管理下)

## The Iron Law

```
EVERY COMMIT DESERVES CONTEXT
NO CONTEXT = NO RECOVERY AFTER COMPACT
SUBAGENT WRITES, PARENT ORCHESTRATES
```

## Prerequisites

- ワークフローがアクティブであること
- PostToolUse hook が設定されていること
- docs/context/ ディレクトリが存在すること（なければ自動作成）

## Document Format

docs/context/CONTEXT.md のフォーマット:

```markdown
# コンテキストドキュメント
最終更新: [YYYY-MM-DD HH:MM] | コミット: [short hash]

## 概要
[プロジェクト/タスクの1-2行説明]

## 現在の状態
- Phase: [X] ([Phase名])
- 進行中: [タスク]
- 次のタスク: [タスク]
- ブランチ: [branch名]

## 意図と目的
[なぜこの変更をしているか、背景、ユーザーの要望]

## 実装経緯
| # | コミット | 変更内容 | 意図 |
|---|---------|---------|------|
| 1 | [hash] | [概要] | [なぜ] |

## 重要な決定事項
| 決定 | 理由 | 代替案 |
|------|------|--------|
| [何を] | [なぜ] | [他の選択肢] |

## ミスと教訓
| ミス | 原因 | 対策 |
|------|------|------|
| [何が] | [なぜ] | [どうした] |

## 用語定義
| 用語 | 定義 |
|------|------|
| [term] | [definition] |

## ユーザーとの対話要約
- [重要な指示や方針の要約]
- [ユーザーの好み、制約]

## compact後の再開手順
1. このファイルを読む
2. git log --oneline -10 で最新状態確認
3. /dev status でワークフロー状態確認
4. 上記「現在の状態」のPhaseとタスクを続行
```

## The Process

### トリガーフロー

```
git commit 完了
  ↓
PostToolUse hook が検出
  ↓
hook が Claude に指示を出力
  ↓
Claude がサブエージェントを起動
  ↓
サブエージェントが docs/context/CONTEXT.md を更新
  ↓
git add + git commit （コンテキストドキュメント用コミット）
```

### サブエージェントへの指示テンプレート

```
Task(subagent_type="general-purpose", model="sonnet"):
  ## コンテキストドキュメント更新

  ### 対象ファイル
  [worktree]/docs/context/CONTEXT.md

  ### 手順
  1. git log --oneline -5 で最新コミットを確認
  2. git diff HEAD~1..HEAD --stat で変更ファイルを確認
  3. docs/context/CONTEXT.md を読む（存在しなければ新規作成）
  4. 以下のセクションを更新:
     - 現在の状態
     - 実装経緯テーブルに最新コミットを追加
     - 重要な決定事項（あれば）
     - ミスと教訓（あれば）
     - ユーザーとの対話要約（重要な指示があれば）
  5. ファイルを書き込む
  6. git add docs/context/CONTEXT.md
  7. git commit -m "docs(context): コンテキストドキュメント更新"
```

### compact後の再注入手順

compact 発生後にコンテキストを復元する手順:

1. docs/context/CONTEXT.md を読む
2. ワークフロー状態を確認: /dev status
3. git log --oneline -10 で最新コミットを確認
4. CONTEXT.md の「現在の状態」セクションに従ってタスクを再開

## Completion Criteria

- [ ] docs/context/CONTEXT.md が存在する
- [ ] 最新コミットが実装経緯に記載されている
- [ ] 現在の状態が正確に反映されている
- [ ] compact後の再開手順が明記されている

## Red Flags

| Thought | Reality |
|---------|---------|
| "コンテキストドキュメントは不要" | compact後に全文脈を失う |
| "コミットメッセージで十分" | 構造化されたドキュメントの方が再注入が容易 |
| "手動で書く" | サブエージェントで自動化すべき |
| "毎回更新は過剰" | コミット毎の差分更新はコストが低い |
| "親エージェントで直接書く" | サブエージェントに委譲してコンテキスト汚染を防ぐ |

## Integration

### Related Skills
- `context-preservation` - コミットメッセージ経由のコンテキスト保存（補完関係）
- `context-circulation` - サブエージェント間のコンテキスト共有
- `dev-workflow` - メインオーケストレーター

### Hooks
- `PostToolUse: check-commit-context.sh` - git commit検出トリガー

### Relationship with context-preservation

context-preservation はコミットメッセージにコンテキストを埋め込む戦略。
context-doc は独立したドキュメントファイルとしてコンテキストを管理する戦略。
両方を併用することで、より堅牢なコンテキスト復元が可能になる。
