---
name: dev-workflow
description: 開発タスクを受けた時、機能実装・バグ修正・リファクタリングの前に使用。7フェーズを自動で進行させるメインオーケストレーター。
---

# Development Workflow Orchestrator

## Overview

開発タスクを7つのフェーズで体系的に進行させるオーケストレーター。
一般的に破綻しにくい順序で、堅実な実装を実現する。

**Core principle:** 縦に切って最短で動かす。水平に全部やろうとしない。

## The Iron Law

```
NO IMPLEMENTATION WITHOUT DESIGN FIRST
NO DESIGN WITHOUT REQUIREMENTS FIRST
NO MERGE WITHOUT VERIFICATION
```

## The Seven Phases

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: 要件定義   何を作るか                              │
│  ─────────────────────────────────────────────────────────  │
│  KPI・成功条件 → ユースケース → 非機能要件 → 制約            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 2: 調査       既存コードを把握                        │
│  ─────────────────────────────────────────────────────────  │
│  既存実装の棚卸し → 再利用可能なコード特定 → 差分分析        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 3: 設計       どう作るかの骨格                        │
│  ─────────────────────────────────────────────────────────  │
│  アーキ設計 → インターフェース設計 → テスト設計              │
└─────────────────────────────────────────────────────────────┘
                              ↓ ★ユーザー承認
┌─────────────────────────────────────────────────────────────┐
│  Phase 4: レビュー   計画を批判的に検証                      │
│  ─────────────────────────────────────────────────────────  │
│  既存実装照合 → 要件カバレッジ → 設計レビュー                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 5: 実装       縦スライスで最短で動かす                │
│  ─────────────────────────────────────────────────────────  │
│  TDD (RED→GREEN→REFACTOR) → タスク単位でコミット            │
└─────────────────────────────────────────────────────────────┘
                              ↓ ★ユーザー承認
┌─────────────────────────────────────────────────────────────┐
│  Phase 6: 検証       リリース前ゲート                        │
│  ─────────────────────────────────────────────────────────  │
│  統合テスト → E2E → セキュリティ → 負荷（必要なら）          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 7: 完了       作って終わりにしない                    │
│  ─────────────────────────────────────────────────────────  │
│  ログ・メトリクス → ロールバック手順 → 監視設定              │
└─────────────────────────────────────────────────────────────┘
```

## Phase Summary

| Phase | Name | Skill | Approval | 成果物 |
|-------|------|-------|----------|--------|
| 1 | 要件定義 | requirements | Auto | 受け入れ条件、I/O定義 |
| 2 | 調査 | investigation | Auto | 実装棚卸し、再利用コード特定 |
| 3 | 設計 | design | **Required** | アーキ、API仕様、テスト設計 |
| 4 | レビュー | codex-review | Auto | レビュー結果 |
| 5 | 実装 | implementation | **Required** | 動作するコード + テスト |
| 6 | 検証 | verification | Auto | テスト結果、検証レポート |
| 7 | 完了 | completion | Auto | 監視設定、ドキュメント |

---

## Phase 1: 要件定義（何を作るか）

### 目的
実装に入る前に「何を作るか」を完全に明確にする。

### 必須項目

| 項目 | 内容 |
|------|------|
| KPI/成功条件 | この変更で何が改善されるか（数値化できれば尚良） |
| ユースケース | 誰が何をしたいか（アクター + アクション + 目的） |
| 非機能要件 | 性能、セキュリティ、可用性、運用性 |
| 制約 | 予算、期限、既存資産、規制、技術スタック |

### 成果物

```markdown
## 要件定義: [タスク名]

### 成功条件
- [ ] [具体的な成功条件 1]
- [ ] [具体的な成功条件 2]

### ユースケース
| アクター | アクション | 目的 |
|---------|----------|------|
| [誰が] | [何をする] | [なぜ] |

### 非機能要件
| 種別 | 要件 |
|------|------|
| 性能 | [レスポンス時間、スループット] |
| セキュリティ | [認証、認可、データ保護] |
| 可用性 | [SLA、冗長化] |

### 制約
- [技術制約]
- [期限制約]
- [既存資産との互換性]

### 受け入れ条件 (Acceptance Criteria)
- [ ] [AC 1]
- [ ] [AC 2]
- [ ] [AC 3]

### I/O定義（最低限）
[画面/APIの入出力]
```

### 完了条件
- [ ] 成功条件が明確
- [ ] ユースケースが網羅
- [ ] 非機能要件が特定
- [ ] 制約が把握
- [ ] 受け入れ条件が定義

---

## Phase 2: 調査（既存コードを把握）

### 目的
既存コードを正確に把握し、再利用可能なコードを特定する。

### 必須項目
- 既存実装の棚卸し（ファイルを実際に読む）
- 再利用可能なコード特定
- 差分分析（複数実装がある場合）

### 成果物
→ `investigation` スキル参照

### 完了条件
- [ ] 関連ファイルを実際に読んだ
- [ ] 実装サマリーを作成
- [ ] 再利用可能コードを特定
- [ ] 「新規」と「既存拡張」を区別

---

## Phase 3: 設計（どう作るかの骨格）

### 目的
実装の前に「どう作るか」の骨格を固める。

### 3段階の設計

#### A. アーキ設計
- 境界を切る（フロント/バック/DB/外部連携）
- ドメイン境界（モジュール、サービス境界）
- データモデル（ER、主要テーブル）
- 非機能の当て方（キャッシュ、冗長化、認証認可）

#### B. インターフェース設計（契約を先に固める）
- API仕様（OpenAPI等）
- DBスキーマ/マイグレーション
- イベント/キュー（使うなら）
- 例外・エラーコード・リトライ方針

#### C. テスト設計（実装前に"壊れ方"を決める）
- 重要フロー（売上、課金、権限、データ整合性）
- 境界値（上限、0、空、異常系）
- 外部依存（落ちる、遅い、返す値が変）
- 同時実行（重複登録、二重決済）

### 成果物
→ `design` スキル参照

### 完了条件（★ユーザー承認必須）
- [ ] アーキ構成図
- [ ] API/DBスキーマ定義
- [ ] テストケース設計
- [ ] 重要な設計判断の記録

---

## Phase 4: レビュー（計画を批判的に検証）

### 目的
Codexによる2観点の批判的レビューで品質を保証。

### 2観点レビュー
1. **既存実装照合**: 計画が既存コードと矛盾していないか
2. **要件カバレッジ**: すべての要件が計画に含まれているか

### 成果物
→ `codex-review` スキル参照

### 完了条件
- [ ] 既存実装照合レビュー完了
- [ ] 要件カバレッジレビュー完了
- [ ] 指摘事項を修正

---

## Phase 5: 実装（縦に切って最短で動かす）

### 目的
縦スライスで、UI→API→DBを1機能ずつ通す。

### 原則
- **縦スライス**: 水平に全部やらず、1機能を端から端まで
- **TDD**: RED→GREEN→REFACTOR
- **早めに動かす**: 本番に近い環境で早期確認

### 成果物
→ `implementation` スキル参照

### 完了条件（★ユーザー承認必須）
- [ ] 全タスク完了
- [ ] 各タスクにテスト
- [ ] 全テスト Pass
- [ ] コードレビュー完了

---

## Phase 6: 検証（リリース前ゲート）

### 目的
リリース前に自動化可能な検証を実施。

### 検証項目

| 種別 | 内容 | 自動化 |
|------|------|--------|
| 統合テスト | コンポーネント間連携 | 必須 |
| E2E | 主要導線（3-10本） | 必須 |
| セキュリティ | OWASP Top 10 | 推奨 |
| 負荷 | 主要APIの性能 | 必要時 |

### 手動確認
- 最小限に抑える
- チェックリスト化

### 成果物
→ `verification` スキル参照

### 完了条件
- [ ] 統合テスト Pass
- [ ] E2E Pass
- [ ] セキュリティチェック完了
- [ ] 手動確認チェックリスト完了

---

## Phase 7: 完了（作って終わりにしない）

### 目的
運用を見据えた準備を完了させる。

### 必須項目

| 項目 | 内容 |
|------|------|
| ログ | 追跡ID、エラーログ |
| メトリクス | 主要KPI、エラー率 |
| アラート | 閾値、通知先 |
| ロールバック | 手順書、タイムライン |
| 監視ダッシュボード | 必要なグラフ |
| 障害対応フロー | エスカレーション |

### 成果物
→ `completion` スキル参照

### 完了条件
- [ ] 監視設定完了
- [ ] ロールバック手順書
- [ ] ドキュメント更新
- [ ] PR作成 or マージ

---

## Workflow State Management

State is stored in `~/.claude/fractal-workflow/{workflow-id}.json`:

```json
{
  "workflowId": "wf-20260212-001",
  "taskDescription": "タスクの説明",
  "status": "active",
  "currentPhase": 3,
  "phases": {
    "1": {"status": "completed", "completedAt": "..."},
    "2": {"status": "completed", "completedAt": "..."},
    "3": {"status": "in_progress", "startedAt": "..."},
    "4": {"status": "pending"},
    "5": {"status": "pending"},
    "6": {"status": "pending"},
    "7": {"status": "pending"}
  },
  "artifacts": {
    "requirements": "path/to/requirements.md",
    "design": "path/to/design.md",
    "testResults": "path/to/test-results.json"
  }
}
```

## Usage

```
/dev [task description]  # Start new workflow
/dev resume              # Resume interrupted workflow
/dev status              # Show current state
/dev cancel              # Cancel workflow
```

## Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "This is simple, I can skip phases"
- "I already know what to do"
- "Let me just code this quickly"
- "Planning is overkill for this"
- "The user wants it fast"

**ALL of these mean: STOP. Follow the full process.**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Simple task, no need for phases" | Simple tasks have hidden complexity |
| "Already done this before" | Context changes, assumptions differ |
| "User wants speed" | Rework from skipped phases takes longer |
| "Investigation is obvious" | Existing code often has reusable patterns |
| "Review is overkill" | External review catches 2-3x more issues |
| "Tests can come later" | Later tests catch fewer bugs |

## Integration

**Required skills:**
- requirements - Phase 1
- investigation - Phase 2
- design - Phase 3
- codex-review - Phase 4
- implementation - Phase 5
- verification - Phase 6
- completion - Phase 7

**Optional skills:**
- testing - Detailed test creation guidance
- parallel-implementation - For parallel subagent execution
- context-circulation - For commit-based context sharing
- failure-memory - For learning from failures
