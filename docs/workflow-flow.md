# fractal-dev-workflow フロー図

9フェーズワークフローの遷移ロジック、レビューフロー、エージェント構成を視覚化したリファレンスドキュメントです。

## 全体フロー図

9フェーズの遷移と条件を示します。Phase 3→4のみユーザー承認が必須で、それ以外はすべて自動遷移です。Phase 4とPhase 7ではCodexレビューが必須であり、Codex利用不可時はqaエージェントにフォールバックします。

```mermaid
flowchart TD
    START([タスク受領]) --> WT[worktree作成\nworkflow/{workflowId}]
    WT --> P1[Phase 1: 質問 + 要件定義]
    P1 -->|自動| P2[Phase 2: 調査 + ドメイン整理]
    P2 -->|自動| P3[Phase 3: 契約設計]
    P3 -->|★ユーザー承認必須| P4[Phase 4: Codex計画レビュー]

    P4 -->|自動遷移| P4_FIX{NEEDS_CHANGES?}
    P4_FIX -->|Yes, 3回まで| P4_AUTO[自動修正]
    P4_AUTO --> P4
    P4_FIX -->|No / 3回超| P5[Phase 5: 実装]

    P5 -->|自動| P6[Phase 6: Chromeデバッグ]
    P6 -->|自動: codex-delegate起動必須| P7[Phase 7: Codexコードレビュー]

    P7 -->|自動遷移| P7_FIX{NEEDS_CHANGES?}
    P7_FIX -->|Yes, 3回まで| P7_AUTO[自動修正]
    P7_AUTO --> P7
    P7_FIX -->|No / 3回超| P8[Phase 8: 検証]

    P8 -->|自動| P9[Phase 9: 運用設計]
    P9 --> END([完了])

    P4 -.->|Codex利用不可| QA4[qa agent フォールバック]
    QA4 --> P4_FIX
    P7 -.->|Codex利用不可| QA7[qa agent フォールバック]
    QA7 --> P7_FIX
```

### Phase間遷移ルール

| 遷移 | 条件 | 備考 |
|------|------|------|
| Phase 1 → 2 | 自動 | 要件定義完了後 |
| Phase 2 → 3 | 自動 | 調査完了条件を満たした後 |
| Phase 3 → 4 | ★ユーザー承認必須 | 計画提示→承認後にcodex-delegate起動 |
| Phase 4 → 5 | 自動 | Codexレビュー完了後（NEEDS_CHANGESも3回で自動遷移） |
| Phase 5 → 6 | 自動 | 実装完了後 |
| Phase 6 → 7 | 自動 | Chromeデバッグ完了後、codex-delegate起動必須 |
| Phase 7 → 8 | 自動 | Codexレビュー完了後 |
| Phase 8 → 9 | 自動 | 検証完了後 |
| Phase 9 → 完了 | 自動 | 運用設計完了後 |

---

## モード分岐図

Phase 1の最初のステップでモードを判定します。選択したモードはワークフロー状態の`mode`フィールドに保存され、Phase 3の設計内容と成果物に影響します。

```mermaid
flowchart TD
    START([Phase 1開始]) --> MODE_Q{モード選択\nAskUserQuestion}
    MODE_Q -->|新規作成\n新機能/ページ/API| NC[mode: new-creation]
    MODE_Q -->|既存修正\nバグ修正/改善/リファクタリング| EM[mode: existing-modification]

    NC --> NC_P1[質問フェーズ\n曖昧さ排除]
    EM --> EM_P1[質問フェーズ\n曖昧さ排除]

    NC_P1 --> REQ[要件定義\nMVP境界 + 受け入れ条件]
    EM_P1 --> REQ

    REQ --> P2[Phase 2: 調査]

    P2 --> NC_CHECK{new-creation?}
    NC_CHECK -->|Yes| P3_NC[Phase 3: 詳細設計\nHTMLモック必須\n完全API仕様\nコンポーネント設計]
    NC_CHECK -->|No: existing-modification| P3_EM[Phase 3: 影響調査重視\n影響範囲マップ必須\n依存関係分析\n整合性チェックリスト]

    P3_NC --> APPROVE[★ユーザー承認]
    P3_EM --> APPROVE
    APPROVE --> P4[Phase 4: Codexレビュー]
```

### モード別の重点項目

| 項目 | new-creation | existing-modification |
|------|-------------|----------------------|
| Phase 3 重点 | 詳細設計 | 影響調査 |
| HTMLモック | 必須 | 不要 |
| API仕様 | 完全定義（OpenAPI） | 変更分のみ |
| DBスキーマ | 完全設計 | 変更分のみ |
| 破壊的変更判定 | なし | 必須 |
| Chrome調査（Phase 2） | 不要 | オプション |

---

## Phase 4/7 Codexレビューフロー

Phase 4（計画レビュー）とPhase 7（コードレビュー）は同一のレビューループ構造を持ちます。NEEDS_CHANGES判定時は自動修正→再レビューを最大3回実行し、その後ユーザー承認なしで次フェーズへ自動遷移します。

```mermaid
sequenceDiagram
    participant O as Orchestrator
    participant CD as codex-delegate
    participant CX as Codex 5.3
    participant QA as qa agent
    participant WF as workflow-manager.sh

    O->>CD: codex-delegate起動（Phase 4 or 7）
    CD->>CX: codex-wrapper.sh check（可用性確認）

    alt Codex利用可能
        CX-->>CD: 利用可能
        CD->>CX: Review 1（既存実装照合）
        CX-->>CD: Review 1結果
        CD->>CX: Review 2（要件カバレッジ）
        CX-->>CD: Review 2結果
        CD->>CX: Review 3（契約の整合性）
        CX-->>CD: Verdict（APPROVED / NEEDS_CHANGES）
    else Codex利用不可（フォールバック）
        CX-->>CD: 利用不可
        CD->>QA: QAレビュー依頼（必須・スキップ不可）
        QA-->>CD: Verdict（APPROVED / NEEDS_CHANGES）
    end

    alt APPROVED
        CD->>WF: approve {workflow-id} {phase} codex
        WF-->>CD: 承認記録
        CD->>O: 次Phaseへ自動遷移
    else NEEDS_CHANGES（再レビュー回数 < 3）
        CD->>O: 指摘事項通知
        O->>O: Critical Issues自動修正
        O->>O: 修正内容コミット
        O->>CD: 再レビュー依頼
        Note over CD,CX: 最大3回まで繰り返し
    else NEEDS_CHANGES（再レビュー回数 >= 3）
        CD->>O: 修正内容を報告
        CD->>WF: approve {workflow-id} {phase} codex
        CD->>O: 次Phaseへ自動遷移（ユーザー承認不要）
    end
```

### Verdictの定義

| Verdict | 意味 | 対応 |
|---------|------|------|
| APPROVED | すべての観点でレビュー通過 | 次Phaseへ自動遷移 |
| NEEDS_CHANGES | 修正が必要な指摘あり | 自動修正→再レビュー（最大3回） |
| Critical Issue | セキュリティ脆弱性・データ損失・本番障害リスク | 即時修正必須 |

---

## 追加要望対応フロー

ワークフロー実行中に追加要望が発生した場合、必ず質問・影響調査・スコープ判定の手順を踏みます。フローをスキップした直接実装は禁止です。

```mermaid
flowchart TD
    ADD([追加要望受信]) --> STEP1[Step 1: 質問フェーズ\nAskUserQuestion で詳細を明確化\n変更内容 / 理由 / MVPスコープ]

    STEP1 --> STEP2[Step 2: 影響調査\nTask subagent: investigator\n影響範囲を調査]

    STEP2 --> STEP3{Step 3: スコープ判定}

    STEP3 -->|現在のPhaseに吸収可能\n契約変更不要 + 既存タスクの延長| MERGE[現在のPhaseに統合]
    STEP3 -->|新しいSliceが必要\n契約変更不要 + 独立した機能追加| NEW_SLICE[タスク分解に追加]
    STEP3 -->|設計変更が必要\nAPI/DBスキーマの変更| BACK_P3[Phase 3に戻る]

    MERGE --> STEP4[Step 4: 実装\nTask subagent: coder\nworktreeで作業]
    NEW_SLICE --> STEP4
    BACK_P3 --> P3_REDESIGN[Phase 3: 再設計\n+ ユーザー承認]
    P3_REDESIGN --> STEP4

    STEP4 --> RESUME([元のPhaseに復帰])

    WARN1[Red Flag: 調査なしで直接実装は禁止]
    WARN2[Red Flag: 親エージェントで直接実装は禁止]
    WARN3[Red Flag: worktreeなしの作業は禁止\n（Phase 1で作成済み）]
```

### スコープ判定基準

| 判定 | 条件 | 対応 |
|------|------|------|
| 現在Phaseに吸収 | 契約変更不要、既存タスクの延長 | 現在タスクに統合 |
| 新Sliceが必要 | 契約変更不要、独立した機能追加 | タスク分解に追加 |
| 設計変更必要 | API/DBスキーマの変更が必要 | Phase 3に戻る |

---

## Phase別エージェント役割表

各フェーズの担当エージェント、使用スキル、推奨モデルを整理します。

| Phase | 名称 | 担当エージェント | スキル | 推奨モデル | 承認 |
|-------|------|-----------------|-------|-----------|------|
| 1 | 質問 + 要件定義 | Architect | questioning, requirements | Sonnet | 自動 |
| 2 | 調査 + ドメイン整理 | investigator | investigation | Sonnet | 自動 |
| 3 | 契約設計 | Architect | design | Opus（複雑な判断時）/ Sonnet | **ユーザー承認必須** |
| 4 | Codex計画レビュー | codex-delegate（→ qaフォールバック） | codex-review | Codex 5.3 xhigh | 自動 |
| 5 | 実装 | TechLead → Coder（並列）+ code-simplifier | implementation | Sonnet | 自動 |
| 6 | Chromeデバッグ | chrome-debugger サブエージェント | chrome-debug | Sonnet | 自動 |
| 7 | Codexコードレビュー | codex-delegate（→ qaフォールバック） | codex-review | Codex 5.3 xhigh | 自動 |
| 8 | 検証 | qa（読み取り専用・編集禁止） | verification | Sonnet | 自動 |
| 9 | 運用設計 | Architect | completion | Sonnet | 自動 |

### エージェント使い分け

| エージェント | 役割 | 制約 |
|-------------|------|------|
| Architect | 要件定義・設計・運用設計 | - |
| investigator | 既存実装調査・ドメイン整理 | path:line根拠必須、憶測禁止 |
| codex-delegate | Codexレビュー実行 | スキップ不可 |
| qa | レビューフォールバック・検証 | 編集禁止（指摘のみ） |
| TechLead | タスク分解・並列実装指示 | - |
| Coder | TDD実装 | worktree内で作業（Phase 1で作成済み） |
| code-simplifier | コード簡素化 | 変更3ファイル以上で実行 |
| chrome-debugger | Chrome MCP操作・UI検証 | 並列禁止、ポート3100固定 |

---

## 状態遷移図

workflow-manager.shが管理するワークフローの状態とPhase状態を示します。

### ワークフロー全体の状態

```mermaid
stateDiagram-v2
    [*] --> creating : /dev [task]でワークフロー作成
    creating --> active : worktree作成完了
    active --> completed : Phase 9完了
    active --> cancelled : /dev cancelで中断
    completed --> [*]
    cancelled --> [*]

    state active {
        [*] --> phase_running
        phase_running --> phase_running : 次Phaseへ遷移
        phase_running --> waiting_approval : Phase 3完了\n（ユーザー承認待ち）
        waiting_approval --> phase_running : ユーザー承認
    }
```

### Phase単体の状態

```mermaid
stateDiagram-v2
    [*] --> pending : ワークフロー初期化時
    pending --> in_progress : Phase開始（バナー表示）
    in_progress --> completed : 完了条件を全て満たした
    in_progress --> in_progress : 作業継続中

    state in_progress {
        [*] --> working
        working --> reviewing : Codexレビュー開始\n（Phase 4/7のみ）
        reviewing --> fixing : NEEDS_CHANGES
        fixing --> reviewing : 再レビュー（最大3回）
        reviewing --> [*] : APPROVED or 3回超
    }
```

### Approval（承認）の状態

```mermaid
stateDiagram-v2
    [*] --> pending : Phase 3完了時に生成

    pending --> approved : ユーザー承認\n（approvalType: user）
    pending --> approved : Codex承認\n（approvalType: codex）
    pending --> rejected : 承認拒否

    approved --> [*]
    rejected --> [*]

    note right of approved
        workflow-manager.sh approve
        {workflow-id} {phase} {type}
        で記録
    end note
```

### Phase 5 Slice の状態

```mermaid
stateDiagram-v2
    [*] --> pending : Phase 5開始時
    pending --> in_progress : Slice開始
    in_progress --> simplifying : code-simplifier実行\n（変更3ファイル以上）
    simplifying --> completed : 簡素化完了
    in_progress --> completed : Sliceテスト全Pass\n（変更3ファイル未満）
    completed --> [*]
```

### ワークフロー状態JSONの主要フィールド

| フィールド | 型 | 値 | 説明 |
|-----------|----|----|------|
| `status` | string | `active` / `completed` / `cancelled` | ワークフロー全体の状態 |
| `mode` | string | `new-creation` / `existing-modification` | Phase 1で設定 |
| `currentPhase` | number | 1-9 | 現在実行中のPhase番号 |
| `phases.N.status` | string | `pending` / `in_progress` / `completed` | 各Phaseの状態 |
| `approvals[].approvalType` | string | `user` / `codex` | 承認者の種別 |
| `approvals[].status` | string | `pending` / `approved` / `rejected` | 承認状態 |
| `codexReviews.N.has_critical_issues` | boolean | true / false | Critical Issue有無 |

---

## 参照ドキュメント

- 詳細な実行手順: `skills/dev-workflow/SKILL.md`
- 各スキル詳細: `skills/*/SKILL.md`
- エージェント定義: `agents/*.md`
- 用語定義（Source of Truth）: `skills/dev-workflow/SKILL.md` の Terminologyセクション
