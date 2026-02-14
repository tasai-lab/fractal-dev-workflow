---
name: dev-workflow
description: 開発タスクを受けた時、機能実装・バグ修正・リファクタリングの前に使用。8フェーズを自動で進行させるメインオーケストレーター。
---

# Development Workflow Orchestrator

## Overview

開発タスクを8つのフェーズで体系的に進行させるオーケストレーター。
**事故りにくい順序**で、堅実な実装を実現する。

**Core principles:**
- **質問で曖昧さを徹底排除**（調査前に全ての要件を明確化）
- **そもそもやることを減らす**（MVP境界を決める）
- **独立タスクはサブエージェントで並列化**（Sonnet 4.5 を積極活用）
- **契約を先に固める**（API/スキーマを先、実装は後）
- **縦に切って最短で動かす**（水平に全部やらない）
- **共通化できるものはコンポーネントにする**

## The Iron Law

```
NO IMPLEMENTATION WITHOUT CONTRACT FIRST (API/Schema)
NO CONTRACT WITHOUT DOMAIN MODEL FIRST
NO DOMAIN MODEL WITHOUT REQUIREMENTS FIRST
NO MERGE WITHOUT VERIFICATION
```

## 必須原則（Additional Iron Rules）

### 調査はサブエージェント駆動
Phase 2（調査）は必ずサブエージェントで実行する。
Task(subagent_type="fractal-dev-workflow:investigator")
理由: 親エージェントのコンテキストを汚さない

### トークン消費削減
- 各サブエージェントは独立したコンテキストで作業
- 結果のみを親エージェントに返す
- コンテキスト循環: コミット経由で引継ぎ

### 実装時はworktree必須
Phase 5（実装）は必ずworktreeで作業する。
git worktree add /path/to/worktrees/<branch-name>
理由: 変更の分離、並列作業、安全なロールバック

## Subagent Configuration

サブエージェントは **Sonnet 4.5** を積極的に使用する：

```
Task(subagent_type="implementer", model="sonnet"):
  ...
```

| 用途 | モデル | 理由 |
|------|--------|------|
| 調査・探索 | sonnet | 高速・コスト効率 |
| 実装 | sonnet | バランス良好 |
| 複雑な設計判断 | opus | 深い推論が必要な場合のみ |

## The Eight Phases（事故りにくい順）

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: 質問 + 要件定義   曖昧さ排除 → 何を作るか決定       │
│  ─────────────────────────────────────────────────────────  │
│  AskUserQuestion で曖昧さ排除 → MVP境界 → ユースケース        │
│  → 受け入れ条件(Given/When/Then) → 非機能要件                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 2: 調査+ドメイン整理                                  │
│  ─────────────────────────────────────────────────────────  │
│  既存実装棚卸し → 用語統一 → ビジネスルール → 境界責務分離    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 3: 契約を先に固定（★ハックポイント）                  │
│  ─────────────────────────────────────────────────────────  │
│  API仕様 → DBスキーマ → エラー形式 → リトライ/冪等性方針      │
│  これでフロント・バック・QAが並列化可能になる                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 4: Codex計画レビュー   計画を批判的に検証             │
│  ─────────────────────────────────────────────────────────  │
│  既存実装照合 → 要件カバレッジ → 契約の整合性                 │
└─────────────────────────────────────────────────────────────┘
                              ↓ ★Codex承認 → ★ユーザー承認
┌─────────────────────────────────────────────────────────────┐
│  Phase 5: 縦切りで実装（薄く通して太くする）                  │
│  ─────────────────────────────────────────────────────────  │
│  1機能をUI→API→ドメイン→DBまで最小で通す → 肉付け            │
│  TDD (RED→GREEN→REFACTOR) + コンポーネント化                 │
│  ★worktree必須: git worktree add /path/to/worktrees/<branch> │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 6: Codexコードレビュー                                │
│  ─────────────────────────────────────────────────────────  │
│  実装コードの批判的レビュー + 承認                            │
└─────────────────────────────────────────────────────────────┘
                              ↓ ★Codex承認 → ★ユーザー承認
┌─────────────────────────────────────────────────────────────┐
│  Phase 7: 検証（テストピラミッド）                           │
│  ─────────────────────────────────────────────────────────  │
│  Unit(多) → Integration(中) → E2E(少) → Contract → 負荷     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 8: 運用設計                                          │
│  ─────────────────────────────────────────────────────────  │
│  マイグレーション → ロールバック → Feature Flag → アラート   │
└─────────────────────────────────────────────────────────────┘
```

## Phase Summary

| Phase | Name | Skill | Approval | 成果物 |
|-------|------|-------|----------|--------|
| 1 | 質問 + 要件定義 | questioning → requirements | Auto | MVP境界、受け入れ条件、「やらない」リスト |
| 2 | 調査+ドメイン | investigation | Auto | 用語統一、ビジネスルール、境界責務 |
| 3 | 契約設計 | design | **Required** | API仕様、DBスキーマ、エラー形式 |
| 4 | Codex計画レビュー | codex-review | **Codex→User** | レビュー結果（Codex 5.3 + xhigh） |
| 5 | 実装 | implementation | **Required** | 動作するコード + テスト + コンポーネント |
| 6 | Codexコードレビュー | codex-review | **Codex→User** | コードレビュー結果 + 承認 |
| 7 | 検証 | verification | Auto | テストピラミッド結果、検証レポート |
| 8 | 運用設計 | completion | Auto | ロールバック手順、監視、Feature Flag |

---

## Phase 1: 質問 + 要件定義（曖昧さ排除 → 何を作るか決定）

### 目的
実装に入る前に「何を作るか」と「何をやらないか」を完全に明確にする。
**ここが曖昧だと、後工程が全部"宗教戦争"になる。**

### Step 0: 質問フェーズ（最初に実行）

**全ての要件定義の前に、曖昧さを徹底的に排除する。**

```
questioning の流れ:
1. タスク説明から曖昧な点を特定
2. AskUserQuestion で 2-4 個のオプションを提示
3. 回答が曖昧なら Explore エージェントで調査してから再質問
4. 全ての曖昧さが解消されたら要件定義へ
```

**必ず質問すべき項目:**
- MVP境界（やること / やらないこと）
- 技術選択（複数の選択肢がある場合）
- 非機能要件（性能、セキュリティ要件）
- 既存コードとの互換性

→ `questioning` スキル参照

### Phase 0 思考: そもそもやることを減らす（最重要）

```markdown
## スコープ削減チェックリスト

### やること（MVP）
- [ ] [機能1] - 必須
- [ ] [機能2] - 必須

### やらないこと（Phase 2以降 or 永久に不要）
- [ ] [機能A] - 理由: ...
- [ ] [機能B] - 理由: ...

### 成功条件（KPI）
- [ ] [測定可能な条件 1]
- [ ] [測定可能な条件 2]
```

### 必須項目

| 項目 | 内容 |
|------|------|
| MVP境界 | 何をやるか、**何をやらないか** |
| KPI/成功条件 | この変更で何が改善されるか（数値化） |
| ユースケース | 誰が何をしたいか（アクター + アクション + 目的） |
| 受け入れ条件 | Given/When/Then で書ける形 |
| 非機能要件 | 性能、セキュリティ、可用性、運用、監査、SLA |
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

## Phase 2: 調査 + ドメイン整理

### 目的
既存コードを正確に把握し、ドメイン（ルールの核）を整理する。
**同じものを2つの名前で呼ぶと死ぬ。**

### 必須項目

#### A. 既存実装の棚卸し
- 関連ファイルを実際に Read で読む
- 再利用可能なコード特定
- 差分分析（複数実装がある場合）
- **共通化可能なコンポーネント候補の抽出**

#### B. ドメイン整理（ルールの核）
| 項目 | 内容 |
|------|------|
| 用語統一 | 用語集を作成（同義語、略語の定義） |
| ビジネスルール | 在庫、課金、権限、状態遷移、制約 |
| 境界責務 | モジュール/サービスの責務分離 |

```markdown
## 用語統一

| 用語 | 意味 | 注意 |
|------|------|------|
| Contact | 関係者 | Person と呼ばない |
| Organization | 関係機関 | Company とは異なる |

## ビジネスルール

| ルール | 内容 | 違反時 |
|--------|------|--------|
| Contact は Organization に必ず紐づく | organizationId 必須 | 400 エラー |
| 同一組織内で名前重複は警告 | 登録可能だが警告表示 | - |
```

### 成果物
→ `investigation` スキル参照

### 完了条件
- [ ] 関連ファイルを実際に読んだ
- [ ] 用語統一表を作成
- [ ] ビジネスルールを列挙
- [ ] 境界責務を明確化
- [ ] 共通化可能なコンポーネント候補を特定
- [ ] 「新規」と「既存拡張」を区別

---

## Phase 3: 契約を先に固定（★ハックポイント）

### 目的
**先にここを決めると、フロント・バック・QAが並列化できる。**
契約（インターフェース）を先に固め、実装は後から。

### 3段階の設計

#### A. アーキテクチャ土台（最初に一回だけちゃんとやる）
| 項目 | 内容 |
|------|------|
| 認証/認可 | RBAC/ABAC、既存使用 or 新規 |
| ロギング | 構造化ログ、追跡ID |
| 設定管理 | env、secrets |
| 例外設計 | エラー分類、ハンドリング |
| CI | lint/format/test、デプロイ |

#### B. 契約を先に固定（★最重要）
| 契約 | 形式 | 効果 |
|------|------|------|
| API仕様 | OpenAPI/GraphQL schema | フロント・バック並列化 |
| DBスキーマ | マイグレーションSQL | 構造が先に確定 |
| イベント仕様 | キュー/ストリーム | 非同期処理の契約 |
| エラー形式 | ステータスコード一覧 | エラーハンドリング統一 |
| リトライ/冪等性 | 方針文書 | 障害対応が楽に |

#### C. テスト設計（実装前に"壊れ方"を決める）
| 観点 | テストケース |
|------|-------------|
| 重要フロー | 売上、課金、権限、データ整合性 |
| 境界値 | 上限、0、空、異常系 |
| 外部依存 | 落ちる、遅い、返す値が変 |
| 同時実行 | 重複登録、二重決済、冪等性 |

### コンポーネント化の判断

```markdown
## コンポーネント化候補

### 共通化すべき（2箇所以上で使用）
| コンポーネント | 使用箇所 | 理由 |
|---------------|---------|------|
| BusinessCardScanner | sales, nursing, calls | 同一UI/ロジック |
| PlaceAutocomplete | organization作成, 検索 | Google Places連携 |

### 共通化しない（アプリ固有）
| コンポーネント | 使用箇所 | 理由 |
|---------------|---------|------|
| SalesDashboard | sales のみ | 営業固有の表示 |
```

### 成果物
→ `design` スキル参照

### 完了条件（★ユーザー承認必須）
- [ ] アーキテクチャ土台（認証、ログ、CI）
- [ ] API仕様（OpenAPI等）
- [ ] DBスキーマ/マイグレーション
- [ ] エラー形式・ステータスコード
- [ ] テストケース設計
- [ ] コンポーネント化候補リスト
- [ ] 重要な設計判断の記録（ADR）

---

## Phase 4: Codex計画レビュー（計画を批判的に検証）

### 目的
Codexによる2観点の批判的レビューで品質を保証。

### 2観点レビュー
1. **既存実装照合**: 計画が既存コードと矛盾していないか
2. **要件カバレッジ**: すべての要件が計画に含まれているか

### 成果物
→ `codex-review` スキル参照

### 完了条件（★Codex承認→ユーザー承認必須）
- [ ] 既存実装照合レビュー完了
- [ ] 要件カバレッジレビュー完了
- [ ] 指摘事項を修正
- [ ] ★Codex承認取得
- [ ] ★ユーザー承認取得

---

## Phase 5: 縦切りで実装（薄く通して太くする）

### 目的
1機能を「UI→API→ドメイン→DB」まで最小で通し、動くものを早期に出す。
**仕様の勘違いを早く潰す。**

### 原則
- **縦スライス**: 水平に全部やらず、1機能を端から端まで
- **薄く通す**: まず最小動作、後から肉付け
- **TDD**: RED→GREEN→REFACTOR
- **コンポーネント化**: 2箇所以上で使うものは共通化

### worktree必須

実装は必ずworktreeで作業する:

```bash
git worktree add /path/to/worktrees/<branch-name>
cd /path/to/worktrees/<branch-name>
```

理由:
- 変更の分離（メインブランチを汚さない）
- 並列作業の安全性
- 安全なロールバック

### 縦切り実装の順序

```markdown
## Slice 1: 最小動作版（MVP）
- [ ] 基本データ型
- [ ] 最小API（1エンドポイント）
- [ ] 最小UI（1画面）
- [ ] 正常系Unit Test
→ **ここで一度動かす**

## Slice 2: バリデーション + エラーハンドリング
- [ ] 入力バリデーション
- [ ] エラー型追加
- [ ] UIエラー表示
- [ ] 異常系Unit Test

## Slice 3: 権限・監査・エッジケース
- [ ] 権限チェック
- [ ] 監査ログ
- [ ] 境界値対応
- [ ] Integration Test
```

### サブエージェント活用（Sonnet 4.5）

```
# 並列実装例
Task(subagent_type="implementer", model="sonnet", run_in_background=true):
  Task 1: 型定義 + Unit Test

Task(subagent_type="implementer", model="sonnet", run_in_background=true):
  Task 2: API実装 + Integration Test
```

### 成果物
→ `implementation` スキル参照

### 完了条件（★ユーザー承認必須）
- [ ] 全タスク完了（縦スライス単位）
- [ ] 各タスクにテスト（TDDで作成）
- [ ] 共通コンポーネントを抽出
- [ ] 全テスト Pass
- [ ] コードレビュー完了

---

## Phase 6: Codexコードレビュー

### 目的
実装されたコードに対するCodexによる批判的レビューと承認。

### レビュー観点
1. **コード品質**: 可読性、保守性、パフォーマンス
2. **テストカバレッジ**: ユニット・統合テストの充実度
3. **セキュリティ**: 脆弱性の有無
4. **ベストプラクティス**: 既存コードとの整合性

### 成果物
→ `codex-review` スキル参照

### 完了条件（★Codex承認→ユーザー承認必須）
- [ ] コード品質レビュー完了
- [ ] テストカバレッジ確認完了
- [ ] セキュリティチェック完了
- [ ] 指摘事項を修正
- [ ] ★Codex承認取得
- [ ] ★ユーザー承認取得

---

## Phase 7: 検証（テストピラミッド）

### 目的
テストピラミッドに従い、ROI順でテストを実施。
**Unit(多) → Integration(中) → E2E(少)**

### テスト優先順位（ROI順）

| # | 種類 | 対象 | 量 |
|---|------|------|-----|
| 1 | **Unit** | ドメインロジック、計算、バリデーション | 多 |
| 2 | **Integration** | DB/外部API連携、Repository | 中 |
| 3 | **API Test** | エンドポイントの入出力、認証認可 | 中 |
| 4 | **Contract** | フロント⇄バック、サービス間 | 必要時 |
| 5 | **E2E** | 主要導線（売上直結のみ）3-10本 | 少 |
| 6 | **非機能** | 負荷、セキュリティ、アクセシビリティ | 要件時 |

### テスト観点チェックリスト

| 観点 | チェック |
|------|---------|
| 入力 | 境界値、桁、形式、空、重複、文字種、タイムゾーン |
| 権限 | 水平・垂直権限（誰が何をできるか） |
| 例外 | 外部API落ちた/遅い/部分失敗 |
| 冪等性 | 二重送信、リトライ、重複メッセージ |
| 整合性 | トランザクション、並行更新、ユニーク制約 |
| 監査 | ログ、追跡ID、監査証跡 |
| 互換性 | スキーマ変更の後方互換 |

### 回帰テストの鉄則

```
バグが出たら → 再現テストを書く → それから修正
```

これを**儀式化**する。人間は忘れるので仕組みにする。

### 成果物
→ `verification` スキル参照

### 完了条件
- [ ] Unit Test（ドメインロジック）Pass
- [ ] Integration Test（DB/API境界）Pass
- [ ] API Test（主要エンドポイント）Pass
- [ ] E2E Test（主フローのSmokeのみ）Pass
- [ ] セキュリティチェック完了
- [ ] 回帰テスト（バグ発生箇所）追加済み

---

## Phase 8: 運用設計

### 目的
**後回しにすると炎上する**運用設計を完了させる。
「動いたからOK」で突っ走らない。

### 必須項目

| 項目 | 内容 | 理由 |
|------|------|------|
| マイグレーション | DB変更の適用手順 | ロールバック可能性 |
| ロールバック | 手順書 + タイムライン | 障害時の復旧 |
| Feature Flag | 段階リリースの仕組み | リスク軽減 |
| アラート | 何が起きたら誰が動くか | 問題検知 |
| バックアップ/リストア | 手順確認 | データ保護 |

### アラート設計

| 条件 | 重要度 | 通知先 |
|------|--------|--------|
| エラー率 5%超 | Critical | Slack + PagerDuty |
| レスポンス時間 p95 > 1s | Warning | Slack |
| DB接続 80%超 | Warning | Slack |
| ディスク使用率 90%超 | Critical | Slack + PagerDuty |

### ロールバック判断基準

```markdown
## 即時ロールバック（判断不要）
- エラー率 20%超
- 主要機能が動作しない
- データ損失の可能性

## 判断が必要
- エラー率 5-20%
- 性能劣化（p95 > 2s）
- 一部機能の不具合
```

### 成果物
→ `completion` スキル参照

### 完了条件
- [ ] マイグレーション手順確認
- [ ] ロールバック手順書
- [ ] Feature Flag 設定（必要な場合）
- [ ] アラート設定
- [ ] 監視ダッシュボード
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
    "7": {"status": "pending"},
    "8": {"status": "pending"}
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

## Agent Roles（Asai-Spec Protocol）

各フェーズには担当エージェントがいる。**ユーザーは指揮官、エージェントは執行者。**

| Phase | 担当 Agent | 役割 | Model |
|-------|------------|------|-------|
| 1-3 | **Architect** | 設計参謀：要件を仕様書に変換 | sonnet |
| 4 | **Codex** | 計画の批判的レビュー（codex-delegate経由） | codex |
| 5 | **TechLead** → **Coder** | 技術分解 → TDD実装 | sonnet |
| 6 | **Codex** | コードレビュー + 承認（codex-delegate経由） | codex |
| 7 | **QA** | 品質憲兵：検証のみ、編集禁止 | sonnet |
| 8 | **Architect** | 運用設計 | sonnet |

### Agent 使い分け

```
@Architect   → 設計・仕様作成（docs/prd.md, docs/api_spec.yaml）
@TechLead    → タスク分解（docs/tasks.md）
@Coder       → TDD実装（テスト先行）
@QA          → 品質監査（編集禁止、指摘のみ）
```

### トラブルシューティング

| ケース | 原因 | 対処 |
|--------|------|------|
| AIが仕様を変える | コンテキスト汚染 | **Architect を再起動**して docs/prd.md を再読込 |
| 実装が沼にハマる | アプローチ固執 | **Architect に代替案を提示**させる |
| テスト通らないのに完了主張 | テスト改竄 | **QA にテストコード自体を監査**させる |
| コンテキストがボケる | 会話長すぎ | **`/compact` でリフレッシュ** |

---

## Integration

**Required skills:**
- questioning - Phase 1 (曖昧さ排除)
- requirements - Phase 1 (要件定義)
- investigation - Phase 2
- design - Phase 3
- codex-review - Phase 4 & 6
- implementation - Phase 5
- verification - Phase 7
- completion - Phase 8

**Required agents:**
- architect - Phase 1-3, 8
- tech-lead - Phase 5 (task decomposition)
- coder - Phase 5 (TDD implementation)
- qa - Phase 7 (read-only verification)
- codex-delegate - Phase 4 & 6 (critical review)
- investigator - Phase 2 (codebase exploration)

**Optional skills:**
- testing - Detailed test creation guidance
- parallel-implementation - For parallel subagent execution
- context-circulation - For commit-based context sharing
- failure-memory - For learning from failures
- project-setup - Project initialization with templates
