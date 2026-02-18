# fractal-dev-workflow フロー図

このドキュメントでは、fractal-dev-workflowプラグインの9フェーズワークフローを視覚化します。各フェーズの流れ、遷移条件、サブエージェント構成を理解するためのリファレンスとして利用してください。

## 全体フロー

9フェーズの全体の流れと遷移条件を示します。Phase 4とPhase 7では**Codexレビューが必須**であり、Codex利用不可時はqaエージェントにフォールバックします。

```mermaid
flowchart TD
    START([タスク受領]) --> Q[Phase 1: 質問 + 要件定義]
    Q -->|自動| INV[Phase 2: 調査 + ドメイン整理]
    INV -->|自動| DES[Phase 3: 契約設計]
    DES -->|★ユーザー承認| CR1[Phase 4: Codex計画レビュー]
    CR1 -->|自動遷移| IMP[Phase 5: 実装]
    IMP -->|自動| DBG[Phase 6: Chromeデバッグ]
    DBG -->|自動: codex-delegate起動必須| CR2[Phase 7: Codexコードレビュー]
    CR2 -->|自動遷移| VER[Phase 8: 検証]
    VER -->|自動| OPS[Phase 9: 運用設計]
    OPS --> END([完了])

    subgraph "Codexレビュー（必須）"
        CR1
        CR2
    end

    subgraph "Codex利用不可時"
        CR1 -.->|フォールバック| QA1[qa agent]
        CR2 -.->|フォールバック| QA2[qa agent]
    end
```

### フェーズ間遷移ルール

| 遷移 | 条件 | 備考 |
|------|------|------|
| Phase 1 → 2 | 自動 | 要件定義完了後 |
| Phase 2 → 3 | 自動 | 調査完了条件を満たした場合 |
| Phase 3 → 4 | ★ユーザー承認必須 | 計画をユーザーに提示し承認後にCodexレビュー |
| Phase 4 → 5 | 自動 | Codexレビュー承認後（NEEDS_CHANGESの場合も3回後自動遷移） |
| Phase 5 → 6 | 自動 | 実装完了後、Chromeデバッグ実施 |
| Phase 6 → 7 | 自動 | Chromeデバッグ完了後、Codexレビュー必須 |
| Phase 7 → 8 | 自動 | Codexレビュー承認後 |
| Phase 8 → 9 | 自動 | 検証完了後 |
| Phase 9 → 完了 | 自動 | 運用設計完了後 |

---

## Phase 1: 質問 + 要件定義

曖昧さを徹底的に排除し、MVP境界を明確化します。モード選択によって後続フェーズの実行内容が決定されます。

```mermaid
flowchart TD
    START([Phase 1開始]) --> MODE{モード選択}
    MODE -->|新規作成| NC[new-creation]
    MODE -->|既存修正| EM[existing-modification]
    NC --> ASK[AskUserQuestion で曖昧さ排除]
    EM --> ASK
    ASK --> CLEAR{曖昧さ解消?}
    CLEAR -->|No| INV_SUB[investigator で調査]
    INV_SUB --> ASK
    CLEAR -->|Yes| REQ[要件定義]
    REQ --> MVP[MVP境界 + やらないリスト]
    MVP --> AC[受け入れ条件 Given/When/Then]
    AC --> NFR[非機能要件定義]
    NFR --> END([Phase 1完了])
```

### Phase 1の主要アクティビティ

1. **モード選択**: 新規作成 or 既存修正を判定
2. **質問フェーズ**: AskUserQuestionで2-4個のオプションを提示し曖昧さ排除
3. **要件定義**: MVP境界、成功条件、ユースケース、受け入れ条件を記述
4. **非機能要件**: 性能、セキュリティ、可用性要件を定義

### 成果物

- MVP境界（やること/やらないこと）
- 受け入れ条件（Given/When/Then形式）
- 非機能要件（性能、セキュリティ等）

---

## Phase 2: 調査 + ドメイン整理

サブエージェント（investigator）を使用して既存実装を調査し、用語統一とビジネスルール抽出を行います。親エージェントのコンテキストを汚さないため、必ずサブエージェント駆動で実行します。

```mermaid
flowchart TD
    START([Phase 2開始]) --> INV[investigator サブエージェント起動]
    INV --> READ[関連ファイル Read]
    READ --> TERM[用語統一表作成]
    TERM --> BIZ[ビジネスルール列挙]
    BIZ --> BOUND[境界責務分離]
    BOUND --> COMP[共通化候補特定]
    COMP --> CHECK{完了条件確認}
    CHECK -->|NG: 憶測あり| REDO[差し戻し: path:line必須]
    REDO --> READ
    CHECK -->|OK| INV_DOC[Inventory形式でドキュメント化]
    INV_DOC --> END([Phase 2完了])
```

### Phase 2の完了条件検証

- **Inventory形式**: Key Exports/Status/Summary列が必須
- **証拠の最小要件**: `path:line` + コマンド + 結果
- **差し戻し条件**: 「ファイル名から推測」「構造から推測」は却下（憶測禁止）

### 成果物

- 用語統一表
- ビジネスルール一覧
- 境界責務分離マップ
- 共通化候補リスト
- Inventory形式の調査結果

---

## Phase 3: 契約設計

モードに応じて実行内容が分岐します。新規作成モードでは詳細設計を行い、既存修正モードでは影響調査を重視します。

```mermaid
flowchart TD
    START([Phase 3開始]) --> MODE{モード?}
    MODE -->|new-creation| NC_DESIGN[詳細設計]
    MODE -->|existing-modification| EM_DESIGN[影響調査]

    NC_DESIGN --> HTML[HTMLモック]
    HTML --> API[API仕様 OpenAPI]
    API --> COMP[コンポーネント設計]
    COMP --> DB[DBスキーマ]
    DB --> TEST_D[テスト設計]
    TEST_D --> TASK[タスク分解]

    EM_DESIGN --> IMPACT[影響範囲マップ]
    IMPACT --> DEP[依存関係分析]
    DEP --> CONSISTENCY[整合性チェックリスト]
    CONSISTENCY --> BREAK{破壊的変更?}
    BREAK -->|Yes| RECORD_BREAK[破壊的変更を記録]
    BREAK -->|No| TASK_EM[タスク分解]
    RECORD_BREAK --> USER_APPROVAL[ユーザー承認]
    USER_APPROVAL --> TASK_EM

    TASK --> END([Phase 3完了 → Phase 4自動遷移])
    TASK_EM --> END
```

### new-creationモードの設計項目

1. **HTMLモック**: 主要画面のワイヤーフレーム
2. **API仕様**: OpenAPI形式で完全定義
3. **コンポーネント設計**: 再利用可能なUI/ロジック分離
4. **DBスキーマ**: テーブル定義、インデックス、制約
5. **テスト設計**: テストケースの事前設計
6. **タスク分解**: 縦スライス単位での実装タスク

### existing-modificationモードの調査項目

1. **影響範囲マップ**: 変更による影響ファイル/機能の特定
2. **依存関係分析**: 呼び出し元/呼び出し先の洗い出し
3. **整合性チェックリスト**: 既存仕様との整合性確認項目
4. **破壊的変更判定**: API削除、必須フィールド追加、型変更等を検出
5. **タスク分解**: 修正タスクの分解

### 成果物

- **new-creation**: HTMLモック、API仕様、DBスキーマ、コンポーネント設計、タスクリスト
- **existing-modification**: 影響範囲マップ、整合性チェックリスト、タスクリスト

---

## Phase 4/7: Codexレビュー

Phase 4（計画レビュー）とPhase 7（コードレビュー）では、Codex 5.3 xhighによる批判的レビューを実行します。NEEDS_CHANGES判定時は自動修正→再レビューのループを最大3回実行し、その後自動遷移します。

```mermaid
flowchart TD
    START([Codexレビュー開始]) --> DELEGATE[codex-delegate 起動]
    DELEGATE --> CHECK{Codex利用可能?}
    CHECK -->|Yes| R1[Review 1: 既存実装照合]
    CHECK -->|No| QA[qa agent フォールバック（必須）]

    R1 --> R2[Review 2: 要件カバレッジ]
    R2 --> R3[Review 3: 契約の整合性]
    R3 --> VERDICT{Verdict?}
    QA --> VERDICT

    VERDICT -->|APPROVED| AUTO[自動遷移]
    VERDICT -->|NEEDS_CHANGES| FIX[自動修正]
    FIX --> RE{再レビュー回数?}
    RE -->|3回未満| DELEGATE
    RE -->|3回以上| REPORT[修正内容報告 → 自動遷移]
    REPORT --> AUTO
    AUTO --> END([次Phase])
```

### Codexレビューのステップ

| レビュー項目 | 内容 |
|-------------|------|
| Review 1: 既存実装照合 | 既存コードとの一貫性確認 |
| Review 2: 要件カバレッジ | すべての要件が計画/実装でカバーされているか |
| Review 3: 契約の整合性 | API/DBスキーマ/エラー形式の整合性 |

### Verdict判定

- **APPROVED**: 自動で次フェーズに遷移
- **NEEDS_CHANGES**: 自動修正→再レビュー（最大3回）
- **Critical Issue**: セキュリティ脆弱性、データ損失リスク、本番障害リスクがある場合

### フォールバック

Codex利用不可時はqaエージェントで代替レビューを実行します（必須）。

---

## Phase 5: 実装

worktreeを作成し、縦スライス単位でTDDサイクル（RED→GREEN→REFACTOR）を回します。各スライス完了後にcode-simplifierを実行して複雑度を削減します。実装完了後はPhase 6（Chromeデバッグ）に自動遷移します。

```mermaid
flowchart TD
    START([Phase 5開始]) --> WT[worktree作成（必須）]
    WT --> SLICE1[Slice 1: MVP最小動作版]

    subgraph "縦スライス実装（TDD）"
        SLICE1 --> TEST1[RED: テスト作成]
        TEST1 --> IMPL1[GREEN: 最小実装]
        IMPL1 --> REF1[REFACTOR: リファクタ]
        REF1 --> PASS1{テスト Pass?}
        PASS1 -->|No| IMPL1
        PASS1 -->|Yes| PRE_CHECK[コミット前チェック]
        PRE_CHECK --> CHECK_RES{チェック結果}
        CHECK_RES -->|Fail| IMPL1
        CHECK_RES -->|Pass| SIMP1{変更3ファイル以上?}
        SIMP1 -->|Yes| CS1[code-simplifier]
        SIMP1 -->|No| NEXT1{次スライスあり?}
        CS1 --> NEXT1
        NEXT1 -->|Yes| SLICE2[Slice N: 次の縦スライス]
        SLICE2 --> TEST1
    end

    NEXT1 -->|No| COMMIT[実装完了コミット]
    COMMIT --> END([Phase 5完了 → Phase 6自動遷移（Chromeデバッグ）])
```

### TDDサイクル

1. **RED**: 失敗するテストを書く（テストファイルを先に作成）
2. **GREEN**: 最小限のコードでテストをパスさせる（過剰実装しない）
3. **REFACTOR**: 重複排除、可読性向上（テストは常にパス）

### コミット前チェック（自動実行必須）

各コミット前に以下を自動実行:
- `pnpm test`: テスト実行
- `pnpm lint`: リント実行
- `pnpm typecheck`: 型チェック実行（TypeScriptの場合）

**1つでもFail**: コミット禁止

### code-simplifier統合

- **実行条件**: 変更ファイル3以上 or 変更50行以上
- **実行タイミング**: 各スライス完了後
- **スキップ可能**: 条件未満の場合

### 成果物

- 動作するコード
- テストコード（最低限のカバレッジ: 主要関数80%以上）
- 再利用可能なコンポーネント

---

## Phase 8: 検証

テストピラミッドに基づいてUnit→Integration→E2E→Contract→負荷の順でテストを実行します。qaエージェントがテスト実行と結果レポートを担当します。

```mermaid
flowchart TD
    START([Phase 8開始]) --> QA[qa agent 起動]
    QA --> UNIT[Unit Test 実行]
    UNIT --> UNIT_RES{結果}
    UNIT_RES -->|Fail| FIX_UNIT[修正 → 再テスト]
    FIX_UNIT --> UNIT
    UNIT_RES -->|Pass| INT[Integration Test]
    INT --> INT_RES{結果}
    INT_RES -->|Fail| FIX_INT[修正 → 再テスト]
    FIX_INT --> INT
    INT_RES -->|Pass| E2E[E2E Test]
    E2E --> E2E_RES{結果}
    E2E_RES -->|Fail| FIX_E2E[修正 → 再テスト]
    FIX_E2E --> E2E
    E2E_RES -->|Pass| CONTRACT[Contract Test]
    CONTRACT --> LOAD[負荷テスト（任意）]
    LOAD --> REPORT[検証レポート作成]
    REPORT --> END([Phase 8完了])
```

### テストピラミッド

| テストレベル | 数量 | 目的 |
|-------------|------|------|
| Unit Test | 多 | 関数/メソッド単位の動作検証 |
| Integration Test | 中 | モジュール間連携の検証 |
| E2E Test | 少 | ユーザーシナリオの検証 |
| Contract Test | 少 | API契約の検証 |
| 負荷テスト | 任意 | 性能要件の検証 |

### 最低限のテストカバレッジ

- 主要関数の80%以上
- 正常系各1ケース
- 主要異常系各1ケース

### 成果物

- テスト実行結果
- 検証レポート
- カバレッジレポート

---

## Phase 9: 運用設計

デプロイ、ロールバック、監視、Feature Flagの設計を行います。本番環境での安全な運用を保証するための最終フェーズです。

```mermaid
flowchart TD
    START([Phase 9開始]) --> MIG[マイグレーション設計]
    MIG --> ROLL[ロールバック手順]
    ROLL --> FLAG[Feature Flag設定]
    FLAG --> MONITOR[監視・アラート設定]
    MONITOR --> DOC[運用ドキュメント作成]
    DOC --> DEPLOY[デプロイ手順確認]
    DEPLOY --> END([Phase 9完了])
```

### Phase 9の主要アクティビティ

1. **マイグレーション設計**: DBスキーマ変更の手順
2. **ロールバック手順**: 障害時の切り戻し手順
3. **Feature Flag**: 段階的リリースのためのフラグ設定
4. **監視・アラート**: エラー率、レスポンスタイム等のアラート設定
5. **運用ドキュメント**: 運用担当者向けの手順書

### 成果物

- マイグレーション/ロールバック手順
- Feature Flag設定
- 監視・アラート設定
- 運用ドキュメント

---

## サブエージェント構成

各フェーズで使用されるサブエージェントとその役割を示します。独立したタスクはサブエージェントで並列実行することでトークン消費を削減します。

```mermaid
flowchart LR
    subgraph "Phase 1-3"
        A1[Architect agent]
    end
    subgraph "Phase 2（並列起動）"
        INV[investigator agent]
    end
    subgraph "Phase 4"
        CD1[codex-delegate]
        CD1 -.->|fallback| QA1[qa agent]
    end
    subgraph "Phase 5"
        TL[Tech Lead] --> C1[Coder agent 1]
        TL --> C2[Coder agent 2]
        TL --> C3[Coder agent N]
        C1 & C2 & C3 --> CS[code-simplifier]
    end
    subgraph "Phase 6"
        CHR[chrome-debug agent]
    end
    subgraph "Phase 7"
        CD2[codex-delegate]
        CD2 -.->|fallback| QA2[qa agent]
    end
    subgraph "Phase 8"
        QA3[QA agent]
    end
    subgraph "Phase 9"
        A2[Architect agent]
    end
```

### サブエージェントの役割

| エージェント | 使用Phase | 役割 | モデル推奨 |
|-------------|----------|------|-----------|
| Architect | Phase 1, 3, 9 | 要件定義、設計、運用設計 | Opus（複雑な判断時）/ Sonnet |
| investigator | Phase 2 | 既存実装調査、ドメイン整理 | Sonnet 4.5 |
| codex-delegate | Phase 4, 7 | Codexレビュー実行 | Codex 5.3 xhigh |
| qa | Phase 4, 7, 8 | レビューフォールバック、検証 | Sonnet |
| Tech Lead | Phase 5 | タスク分配、進捗管理 | Sonnet |
| Coder | Phase 5 | TDD実装 | Sonnet 4.5 |
| code-simplifier | Phase 5 | コード簡素化 | Sonnet |
| chrome-debug | Phase 6 | Chromeデバッグ実行 | Sonnet |

### 並列実行の原則

- 独立したタスクは`run_in_background=true`で並列実行
- サブエージェントごとに独立したコンテキストで作業
- 結果のみを親エージェントに返す（トークン消費削減）

---

## 追加要望対応フロー

ワークフロー実行中に追加要望が入った場合の対応フローです。影響調査を行い、スコープ判定によって適切に統合または分離します。

```mermaid
flowchart TD
    REQ([追加要望受信]) --> ASK[質問: AskUserQuestion]
    ASK --> INV[影響調査: investigator]
    INV --> JUDGE{スコープ判定}
    JUDGE -->|現在Phaseに吸収| MERGE[現在タスクに統合]
    JUDGE -->|新Sliceが必要| SLICE[タスク分解に追加]
    JUDGE -->|設計変更必要| BACK[Phase 3に戻る]
    MERGE --> IMPL[サブエージェントで実装]
    SLICE --> IMPL
    BACK --> DES[Phase 3: 契約設計]
    DES --> IMPL
    IMPL --> RESUME[元のPhaseに復帰]
```

### スコープ判定基準

| 判定 | 条件 | 対応 |
|------|------|------|
| 現在Phaseに吸収 | 契約変更不要、既存タスクの延長 | 現在タスクに統合 |
| 新Sliceが必要 | 契約変更不要、独立した機能追加 | タスク分解に追加 |
| 設計変更必要 | API/DBスキーマの変更が必要 | Phase 3に戻る |

---

## まとめ

このフロー図は、fractal-dev-workflowの実行フローを視覚化したものです。以下の原則を常に意識してください:

### 重要原則

1. **質問で曖昧さを徹底排除**（Phase 1）
2. **そもそもやることを減らす**（MVP境界の明確化）
3. **契約を先に固める**（Phase 3）
4. **縦に切って最短で動かす**（Phase 5）
5. **サブエージェント駆動**（コンテキスト汚染防止）
6. **Codexレビュー必須**（Phase 4, 7）
7. **TDD厳守**（テストなしのコードはコミット禁止）

### 参照ドキュメント

- 詳細な実装手順: `skills/*/SKILL.md`
- エージェント定義: `agents/*.md`
- 用語定義（Source of Truth）: `skills/dev-workflow/SKILL.md` Terminologyセクション
