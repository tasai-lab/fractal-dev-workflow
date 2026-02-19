---
name: dev-workflow
description: 開発タスクを受けた時、機能実装・バグ修正・リファクタリングの前に使用。9フェーズを自動で進行させるメインオーケストレーター。
---

# Development Workflow Orchestrator

## Terminology (Source of Truth)

このセクションはプラグイン全体の用語定義の**正本（source of truth）**です。
他のスキル/エージェントでは定義を重複記載せず、このセクションを参照してください。

| 用語 | 定義 | 詳細参照 |
|------|------|---------|
| 破壊的変更 | API削除、必須フィールド追加、型変更等 | `design/SKILL.md` |
| 主要画面 | Phase 1で定義したユースケースに登場するすべての画面 | `questioning/SKILL.md` |
| Critical Issue | セキュリティ脆弱性、データ損失リスク、本番障害リスク | `codex-review/SKILL.md` |
| 最低限のテストカバレッジ | 主要関数の80%以上、正常系各1ケース、主要異常系各1ケース | `qa.md` |
| 憶測 | file:line参照を伴わない推測。「ファイル名から推測」「構造から推測」は憶測。根拠（path:line・コマンド実行結果）が不足している場合も差し戻し対象 | `investigation/SKILL.md` |

## Overview

開発タスクを9つのフェーズで体系的に進行させるオーケストレーター。
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

### COMPACT後も必ずサブエージェント駆動を継続
**最重要**: compact後にコンテキストが減っても、以下を守ること:
- 親エージェントで直接実装しない
- 調査 → investigator
- 実装 → coder/implementer
- レビュー → qa
- ドキュメント → doc-reviewer

**compact後の再開手順:**
1. `docs/context/CONTEXT.md` を読む（最重要）
2. `/dev status` でワークフロー状態確認
3. `git log --oneline -5` で最新コンテキスト確認
4. MEMORY.mdを読む
5. サブエージェントでタスク継続

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

## The Nine Phases（事故りにくい順）

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
                              ↓ 自動遷移（Codexレビュー必須）
┌─────────────────────────────────────────────────────────────┐
│  Phase 5: 縦切りで実装（薄く通して太くする）                  │
│  ─────────────────────────────────────────────────────────  │
│  1機能をUI→API→ドメイン→DBまで最小で通す → 肉付け            │
│  TDD (RED→GREEN→REFACTOR) + コンポーネント化                 │
│  ★worktree必須: git worktree add /path/to/worktrees/<branch> │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 6: Chromeデバッグ（実装のUI/挙動を実機検証）          │
│  ─────────────────────────────────────────────────────────  │
│  devサーバー起動 → UI表示確認 → インタラクション検証          │
│  → エラー検出 → 自動修正(最大3回)                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 7: Codexコードレビュー                                │
│  ─────────────────────────────────────────────────────────  │
│  実装コードの批判的レビュー + 承認                            │
└─────────────────────────────────────────────────────────────┘
                              ↓ 自動遷移（Codexレビュー必須）
┌─────────────────────────────────────────────────────────────┐
│  Phase 8: 検証（テストピラミッド）                           │
│  ─────────────────────────────────────────────────────────  │
│  Unit(多) → Integration(中) → E2E(少) → Contract → 負荷     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  Phase 9: 運用設計                                          │
│  ─────────────────────────────────────────────────────────  │
│  マイグレーション → ロールバック → Feature Flag → アラート   │
└─────────────────────────────────────────────────────────────┘
```

## Phase Summary

| Phase | Name | Skill | Approval | 成果物 |
|-------|------|-------|----------|--------|
| 1 | 質問 + 要件定義 | questioning → requirements | Auto | MVP境界、受け入れ条件、「やらない」リスト |
| 2 | 調査+ドメイン | investigation | Auto | 用語統一、ビジネスルール、境界責務、Chrome挙動ベースライン（オプション） |
| 3 | 契約設計 | design | **Required** | API仕様、DBスキーマ、エラー形式 |
| 4 | Codex計画レビュー | codex-review | **Auto（Codex必須）** | レビュー結果（Codex 5.3 + xhigh） |
| 5 | 実装 | implementation | **Required** | 動作するコード + テスト + コンポーネント |
| 6 | Chromeデバッグ | chrome-debug | Auto | UI/挙動検証結果 |
| 7 | Codexコードレビュー | codex-review | **Auto（Codex必須）** | コードレビュー結果 + 承認 |
| 8 | 検証 | verification | Auto | テストピラミッド結果、検証レポート |
| 9 | 運用設計 | completion | Auto | ロールバック手順、監視、Feature Flag |

---

## Mode Selection (Phase 1 開始時)

タスク受領後、**Phase 1の最初のステップ**として以下の質問でモードを判定する:

```
AskUserQuestion:
  question: "このタスクは新規作成と既存修正のどちらですか？"
  header: "モード選択"
  options:
    - label: "新規作成（新しい機能/ページ/API）"
      description: "ゼロから設計。HTMLモック、完全なAPI仕様が必要"
    - label: "既存修正（バグ修正/改善/リファクタリング）"
      description: "既存コード調査重視。影響範囲分析が必要"
```

回答を workflow state の `mode` フィールドに保存:
- "新規作成" → mode: "new-creation"
- "既存修正" → mode: "existing-modification"

以降のフェーズでモードに応じた実行内容を適用。

---

## Phase 1: 質問 + 要件定義（曖昧さ排除 → 何を作るか決定）

### 目的
実装に入る前に「何を作るか」と「何をやらないか」を完全に明確にする。
**ここが曖昧だと、後工程が全部"宗教戦争"になる。**

### Step 1: 質問フェーズ（モード選択後に実行）

**全ての要件定義の前に、曖昧さを徹底的に排除する。**

```
questioning の流れ:
1. タスク説明から曖昧な点を特定
2. AskUserQuestion で 2-4 個のオプションを提示
3. 回答が曖昧なら fractal-dev-workflow:investigator エージェントで調査してから再質問
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

#### C. Chrome挙動確認（オプショナル、existing-modificationモードのみ）

**実行条件**: questioningフェーズで `chromeInvestigation: true` が設定されている場合のみ。

- 変更対象の既存画面をRead-onlyで観察
- 修正前の現在の動作をベースラインとして記録
- Phase 6（Chromeデバッグ）との差異:
  - **Phase 2**: 観察のみ（navigate / get_page_text / read_console_messages）
  - **Phase 6**: 操作・修正・再検証サイクルあり（インタラクション含む）

事前にdevサーバーを起動すること（`chrome-debug` スキルの Step 1 参照）。
→ `investigation` スキルの Step 8 参照

### 成果物
→ `investigation` スキル参照

### 完了条件
- [ ] 関連ファイルを実際に読んだ
- [ ] 用語統一表を作成
- [ ] ビジネスルールを列挙
- [ ] 境界責務を明確化
- [ ] 共通化可能なコンポーネント候補を特定
- [ ] 「新規」と「既存拡張」を区別
- [ ] **（オプショナル）Chrome挙動確認実施済み**（`chromeInvestigation: true` の場合のみ）

---

## Phase 3: 契約を先に固定（★ハックポイント）

### 目的
**先にここを決めると、フロント・バック・QAが並列化できる。**
契約（インターフェース）を先に固め、実装は後から。

### モード別の必須成果物

#### new-creation モード

**必須成果物:**
- [ ] HTMLモック（主要画面すべて）
- [ ] API仕様（OpenAPI形式、完全定義）
- [ ] コンポーネント設計（props型、状態管理、ディレクトリ構成）
- [ ] DBスキーマ/マイグレーション
- [ ] テスト設計
- [ ] タスク分解 + worktree計画

**承認:** ★ユーザー承認必須 → Phase 4 Codexレビューへ

---

#### existing-modification モード

**必須成果物:**
- [ ] 整合性チェックリスト（既存APIとの互換性、既存スキーマとの整合性）
- [ ] API仕様変更（ある場合のみ）
- [ ] DBスキーマ変更（ある場合のみ）
- [ ] タスク分解

**承認:** ★ユーザー承認必須 → Phase 4 Codexレビューへ

---

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

### 完了条件（モード依存の承認フロー）
- [ ] アーキテクチャ土台（認証、ログ、CI）
- [ ] API仕様（OpenAPI等）
- [ ] DBスキーマ/マイグレーション
- [ ] エラー形式・ステータスコード
- [ ] テストケース設計
- [ ] コンポーネント化候補リスト
- [ ] 重要な設計判断の記録（ADR）
- [ ] 承認フロー → **Phase Transition Rules 参照**

---

## Phase 4: Codex計画レビュー（計画を批判的に検証）

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
- [ ] 承認フロー → **Phase Transition Rules 参照**

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

**CRITICAL: worktreeなしでの実装は禁止。以下を Phase 5 開始時に必ず実行すること:**

```bash
# Phase 5 開始時の最初のアクション（スキップ不可）
git worktree add /path/to/worktrees/<branch-name>
cd /path/to/worktrees/<branch-name>
```

**worktree作成前に実装コードを書いてはいけない。**

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

### Code Simplification（各スライス完了時）

各縦スライス実装完了後、コードレビュー前に code-simplifier を実行:

```
Task(subagent_type="code-simplifier:code-simplifier", model="sonnet"):
  ## コード簡素化

  ### 対象
  直近で変更されたファイル

  ### 実行内容
  - 冗長なコードの削減
  - 命名の一貫性確認
  - 不要な抽象化の排除
  - コードの可読性向上

  ### 出力
  - 変更したファイル一覧
  - 各変更の理由
```

**実行タイミング:**
- 各 Slice 完了後
- Phase 7（Codexコードレビュー）前

**スキップ条件:**
- 変更ファイル数が3未満の場合はオプショナル

### 成果物
→ `implementation` スキル参照

### 完了条件
- [ ] 全タスク完了（縦スライス単位）
- [ ] 各タスクにテスト（TDDで作成）
- [ ] 共通コンポーネントを抽出
- [ ] 全テスト Pass
- [ ] code-simplifier 実行（変更ファイル3以上の場合）
- [ ] 実装完了コミット

---

## Phase 6: Chromeデバッグ（実装のUI/挙動を実機検証）

### 目的
実装したコードを実際のブラウザで動作確認し、テストでは検出できないUI/UXの問題を早期に発見する。
**コードレビュー前に実機で確認することで、レビューの質も向上する。**

### 全タスク必須
バックエンドのみの変更でも、影響するUIがある場合はブラウザ確認を行う。

### 実行モデル
**Chrome操作は必ずサブエージェント（sonnet）に委譲する。**
親エージェントは環境準備とオーケストレーションのみ。

```
Task(subagent_type="general-purpose", model="sonnet"):
  Chrome MCPツールでUI/挙動を検証
```

### プロセス

#### Step 1: 環境準備（親エージェント）
- devサーバーを起動（ポート3100、使用中なら3101-3199でフォールバック）

#### Step 2-4: Chrome検証（サブエージェント）
- サブエージェントがChrome MCPツールでUI表示、インタラクション、エラーを検証
- コンソールログ・ネットワークリクエストを確認

#### Step 5: 問題修正サイクル（問題発見時）
- 修正用サブエージェント（coder）で自動修正
- 再検証用サブエージェント（general-purpose）で再確認
- 最大3回まで繰り返し

### 成果物
→ `chrome-debug` スキル参照

### 完了条件
- [ ] 全主要画面の表示確認
- [ ] 全主要インタラクションの動作確認
- [ ] コンソールにJSエラーがゼロ
- [ ] ネットワークリクエストに4xx/5xxがゼロ
- [ ] 問題発見時: 修正済みまたはレポート作成済み

---

## Phase 7: Codexコードレビュー

### 目的
実装されたコードに対するCodexによる批判的レビューと承認。

### レビュー観点
1. **コード品質**: 可読性、保守性、パフォーマンス
2. **テストカバレッジ**: ユニット・統合テストの充実度
3. **セキュリティ**: 脆弱性の有無
4. **ベストプラクティス**: 既存コードとの整合性

### 成果物
→ `codex-review` スキル参照

### 完了条件
- [ ] コード品質レビュー完了
- [ ] テストカバレッジ確認完了
- [ ] セキュリティチェック完了
- [ ] 指摘事項を修正
- [ ] 承認フロー → **Phase Transition Rules 参照**

---

## Phase 8: 検証（テストピラミッド）

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

## Phase 9: 運用設計

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

## Phase Transition Flow（自動遷移ロジック）

**CRITICAL: 各フェーズ完了時は以下のトリガーを実行する**

### Phase Transition Rules

#### Phase 3 → Phase 4

**条件:** ★ユーザー承認必須（全モード共通）
- Phase 3完了 → 計画をユーザーに提示 → 承認後 codex-delegate を起動して Phase 4 開始
- new-creation / existing-modification に関わらず常にユーザー承認が必要

#### Phase 4 → Phase 5

**条件:** 常に自動遷移
- Codexレビュー完了 → Critical Issuesがあれば自動修正 → 自動遷移
- Codex利用不可 → qaエージェントでフォールバック → 自動遷移
- ユーザー承認不要

#### Phase 5 → Phase 6

**条件:** 常に自動遷移
- 実装完了 → chrome-debugスキルに従いブラウザで実機検証 → 自動遷移
- ユーザー承認不要

#### Phase 6 → Phase 7

**条件:** 常に自動遷移（codex-delegate 起動必須）
- Chromeデバッグ完了 → codex-delegate を起動して Phase 7 開始
- Codex利用不可 → qaエージェントでフォールバック → 自動遷移
- ユーザー承認不要

#### Phase 7 → Phase 8

**条件:** 常に自動遷移
- Codexコードレビュー完了 → Critical Issuesがあれば自動修正 → 自動遷移
- Codex利用不可 → qaエージェントでフォールバック → 自動遷移
- ユーザー承認不要

---

### NEEDS_CHANGES時の再レビューフロー

Phase 4またはPhase 7でCodexが`NEEDS_CHANGES`を返した場合:

1. **指摘事項を自動修正**
   - Critical Issuesをすべて修正
   - 修正内容をコミット

2. **再レビュー実行**
   - codex-delegateを再度起動
   - 修正後のコードをレビュー

3. **判定**
   - APPROVED → 次Phaseへ自動遷移
   - NEEDS_CHANGES（再び） → Step 1に戻る

最大3回の再レビューまで。それ以上は修正内容を報告して自動遷移。
ユーザー承認は不要。

---

### Phase 3 → Phase 4 遷移（計画レビュー）

Phase 3（契約設計）完了後、**ユーザー承認を取得してから** codex-delegate を起動してPhase 4を開始。
**計画の承認はスキップ不可。**

```
# Phase 3 完了後 → 必ず実行
Task(subagent_type="fractal-dev-workflow:codex-delegate", model="haiku"):
  ## Phase 4: Codex計画レビュー

  計画ファイル: [design artifact path]
  要件ファイル: [requirements artifact path]

  以下の手順でレビューを実行してください:
  1. scripts/codex-wrapper.sh check でCodex可用性を確認
  2. 利用可能な場合: review-spec と review-requirements を順次実行
  3. 利用不可の場合: 以下のフォールバックを実行

  ★Codex利用不可時のフォールバック（必須）:
  Task(subagent_type="fractal-dev-workflow:qa"):
    ## QA Review (Codex Fallback)
    計画ファイルを読み、既存実装との整合性と要件カバレッジをレビュー

  結果を以下の形式で報告:
  - Review 1 (既存実装照合): [結果]
  - Review 2 (要件カバレッジ): [結果]
  - Verdict: [APPROVED / NEEDS CHANGES]
```

### Phase 5 → Phase 6 遷移（Chromeデバッグ）

Phase 5（実装）完了後、自動的にPhase 6（Chromeデバッグ）を開始。
chrome-debugスキルに従い、ブラウザで実機検証を実行する。

### Phase 6 → Phase 7 遷移（コードレビュー）

Phase 6（Chromeデバッグ）完了後、**必ず** codex-delegate を起動してPhase 7を開始。
**スキップ不可。ユーザー承認不要。**

```
# Phase 6 完了後 → 必ず実行
Task(subagent_type="fractal-dev-workflow:codex-delegate", model="haiku"):
  ## Phase 7: Codexコードレビュー

  実装コミット: [latest commits]

  scripts/codex-wrapper.sh review . uncommitted を実行し、
  コード品質・テストカバレッジ・セキュリティを評価してください。

  ★Codex利用不可時のフォールバック（必須）:
  Task(subagent_type="fractal-dev-workflow:qa"):
    ## QA Code Review (Codex Fallback)
    実装コードの品質・テストカバレッジ・セキュリティをレビュー
```

### 遷移フローチャート

```
Phase 1 完了 → Phase 2 開始（自動）
Phase 2 完了 → Phase 3 開始（自動）
Phase 3 完了 → ★ユーザー承認 → Phase 4 開始（codex-delegate 起動必須）
Phase 4 完了 → Phase 5 開始（自動）
Phase 5 完了 → Phase 6 開始（自動: Chromeデバッグ）
Phase 6 完了 → Phase 7 開始（自動: codex-delegate 起動必須）
Phase 7 完了 → Phase 8 開始（自動）
Phase 8 完了 → Phase 9 開始（自動）
```

### トリガーチェックリスト

フェーズ完了時に確認:
- [ ] 完了条件をすべて満たしているか
- [ ] 状態ファイルを更新したか (`~/.claude/fractal-workflow/{id}.json`)
- [ ] Phase 4, 7: codex-delegate を起動したか（必須、スキップ不可）
- [ ] Phase 4, 7: Codex利用不可の場合、qaフォールバックを実行したか

---

## Memory Recording（Phase終了時の学び記録）

### 目的
各フェーズ完了時に学びを記録し、次回以降のワークフローで活用する。

### 記録タイミング
- 各Phase完了時
- 失敗パターン検出時（failure-memory連携）
- 重要な決定事項発生時

### 記録先
- `~/.claude/projects/{project-path}/memory/MEMORY.md` - 主要な学び
- `~/.claude/projects/{project-path}/memory/*.md` - 詳細トピック別

### Phase終了時の記録項目

| Phase | 記録内容 |
|-------|---------|
| 1 | 要件の曖昧さパターン、よくある質問 |
| 2 | コードベースの重要な発見、再利用パターン |
| 3 | 契約設計の決定事項とその理由 |
| 4 | Codexレビューで指摘された問題パターン |
| 5 | 実装時の技術的課題と解決策 |
| 6 | Chromeデバッグで発見したUI/UX問題と修正内容 |
| 7 | コードレビューの指摘パターン |
| 8 | テストで発見した問題と対策 |
| 9 | 運用設計のベストプラクティス |

### 記録フォーマット
```markdown
## [YYYY-MM-DD] Phase X 完了

### 学び
- [具体的な学び1]
- [具体的な学び2]

### 次回への申し送り
- [注意点1]
- [注意点2]
```

### failure-memory連携
2回以上同じパターンの失敗が発生した場合:
1. failure-memoryスキルを呼び出し
2. `~/.claude/fractal-workflow/failure-memory.json` に記録
3. memoryにも要約を追記

---

## Commit Context Preservation（コミット時のコンテキスト保存）

### 目的
compact後のコンテキスト再注入用に、コミットを具体的で再開可能な資料にする。

### コミットメッセージテンプレート

```
feat(scope): 簡潔な説明

## 作業状態
- 現在のフェーズ: Phase X
- 完了したタスク: [リスト]
- 次のタスク: [リスト]

## 重要な決定事項
- [決定1]: [理由]

## 再開時の注意点
- [注意点1]

## 関連ファイル
- path/to/file1: [変更概要]

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 必須項目
- 作業状態（Phase、完了/未完了タスク）
- 重要な決定事項とその理由
- 再開時の注意点

### context-preservationスキル連携
詳細な資料作成が必要な場合は context-preservation スキルを使用。

### context-docによる自動ドキュメント生成

コミット毎にPostToolUse hookが発火し、サブエージェント（sonnet）が `docs/context/CONTEXT.md` を自動更新する。

**フロー:**
1. git commit完了 → PostToolUse hook (check-commit-context.sh) が検出
2. hookがClaudeに更新指示を出力
3. Claudeがサブエージェントを起動してドキュメント更新
4. サブエージェントが git add + commit

**compact後の再注入:**
1. `docs/context/CONTEXT.md` を読む
2. `/dev status` でワークフロー状態確認
3. `git log --oneline -10` で最新コミット確認
4. タスク続行

→ `context-doc` スキル参照

---

## Additional Requirements Handling（追加要望対応フロー）

### 目的
ワークフロー実行中に追加要望が発生した場合、適切なフローで対応する。
**追加要望を受けても、フローをスキップしない。**

### 追加要望発生時のフロー

```
追加要望を受信
  ↓
Step 1: 質問フェーズ（必須）
  AskUserQuestion で追加要望の詳細を明確化
  - 何を変更するか
  - なぜ変更するか
  - MVPスコープ
  ↓
Step 2: 影響調査（必須・サブエージェント駆動）
  Task(subagent_type="fractal-dev-workflow:investigator"):
    追加要望の影響範囲を調査
  ↓
Step 3: スコープ判定
  - 現在のPhaseに吸収可能 → 現在のPhaseに統合
  - 新しいSliceが必要 → タスク分解に追加
  - 設計変更が必要 → Phase 3に戻る
  ↓
Step 4: 実装（サブエージェント駆動）
  Task(subagent_type="fractal-dev-workflow:coder"):
    追加要望の実装
```

### Red Flags

| Thought | Reality |
|---------|---------|
| "簡単だからそのまま実装" | 質問と調査をスキップするな |
| "現在のタスクに含めよう" | 影響調査なしで統合するな |
| "親エージェントで直接やる" | サブエージェント駆動を守れ |
| "worktreeは不要" | 追加実装もworktreeで作業 |

---

## Workflow State Management

State is stored in `~/.claude/fractal-workflow/{workflow-id}.json`:

```json
{
  "workflowId": "wf-20260212-001",
  "taskDescription": "タスクの説明",
  "status": "active",
  "mode": "new-creation | existing-modification",
  "chromeInvestigation": false,
  "currentPhase": 3,
  "phases": {
    "1": {"status": "completed", "completedAt": "..."},
    "2": {"status": "completed", "completedAt": "..."},
    "3": {
      "status": "in_progress",
      "startedAt": "...",
      "has_breaking_changes": false
    },
    "4": {"status": "pending"},
    "5": {"status": "pending"},
    "6": {"status": "pending"},
    "7": {"status": "pending"},
    "8": {"status": "pending"},
    "9": {"status": "pending"}
  },
  "approvals": [
    {
      "phase": 3,
      "approvalType": "user | codex",
      "status": "pending | approved | rejected",
      "requestedAt": "...",
      "approvedAt": "...",
      "reason": "new-creation mode | breaking changes detected | critical issues found"
    }
  ],
  "codexReviews": {
    "4": {
      "critical_issues_count": 0,
      "has_critical_issues": false
    },
    "7": {
      "critical_issues_count": 0,
      "has_critical_issues": false
    }
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
| 5-6間 | **code-simplifier** | コード簡素化・品質向上 | sonnet |
| 6 | **Subagent (sonnet)** | Chrome MCP操作 + UI/挙動検証 | sonnet |
| 7 | **Codex** | コードレビュー + 承認（codex-delegate経由） | codex |
| 8 | **QA** | 品質憲兵：検証のみ、編集禁止 | sonnet |
| 9 | **Architect** | 運用設計 | sonnet |

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
- codex-review - Phase 4 & 7
- implementation - Phase 5
- chrome-debug - Phase 6
- verification - Phase 8
- completion - Phase 9

**Required agents:**
- architect - Phase 1-3, 9
- tech-lead - Phase 5 (task decomposition)
- coder - Phase 5 (TDD implementation)
- qa - Phase 8 (read-only verification)
- codex-delegate - Phase 4 & 7 (critical review)
- investigator - Phase 2 (codebase exploration)

**Optional skills:**
- testing - Detailed test creation guidance
- parallel-implementation - For parallel subagent execution
- context-circulation - For commit-based context sharing
- failure-memory - For learning from failures
- project-setup - Project initialization with templates
- context-doc - Automatic context documentation per commit
