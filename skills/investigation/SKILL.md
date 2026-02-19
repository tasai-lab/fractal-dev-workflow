---
name: investigation
description: 要件確定後、計画策定の前にコードベースと外部情報の調査が必要な時に使用。サブエージェントとCodexで並列調査を実行。
---

# Investigation Phase

## Overview

計画を立てる前に、コードベースと外部情報のエビデンスを収集する。

**Core principle:** NEVER plan without evidence-based investigation first.

## Investigation Scope by Mode

### new-creation モード
**調査観点:**
- 既存実装の棚卸し（再利用可能コード）
- 用語統一
- ビジネスルール
- 共通化可能なコンポーネント候補

### existing-modification モード（★強化）
**調査観点:**
- **変更対象ファイルの完全読み込み（必須）**
- **依存関係分析（呼び出し元/呼び出し先）（必須）**
- **影響範囲マップ（必須）**
- 既存テストの棚卸し
- 用語統一
- ビジネスルール確認

## The Iron Law

```
NO PLANNING WITHOUT EVIDENCE-BASED INVESTIGATION FIRST
NO FILE LISTING WITHOUT READING ACTUAL CONTENT
```

## The Process

```dot
digraph investigation {
    "Requirements confirmed" -> "Create investigation plan";
    "Create investigation plan" -> "Parallel Investigation";

    subgraph cluster_parallel {
        label="Parallel Investigation";
        "Subagent 1: Related code" [shape=box];
        "Subagent 2: Dependencies" [shape=box];
        "Subagent 3: Test patterns" [shape=box];
        "Codex: External research" [shape=box];
    }

    "Parallel Investigation" -> "Existing Implementation Inventory";
    "Existing Implementation Inventory" -> "Read and Summarize Files";
    "Read and Summarize Files" -> "Diff Analysis";
    "Diff Analysis" -> "Document findings";
    "Document findings" -> "Verify completion";
}
```

### Step 1: Investigation Planning
Identify areas to investigate:
- Related existing code sections
- Available utilities and patterns
- External library/API specifications
- Similar implementation references

### Step 2: Parallel Investigation

**Subagent investigations (max 3 parallel):**
```
Task(subagent_type="fractal-dev-workflow:investigator", model="haiku"):
  - Investigation 1: Identify related existing code
  - Investigation 2: Analyze dependencies and impact
  - Investigation 3: Find test patterns and utilities
```

**Codex parallel investigation (when available):**
```bash
CODEX_REASONING=xhigh scripts/codex-wrapper.sh exec "$PROJECT_DIR" \
  "以下の調査を行ってください: [investigation content]"
```

### Step 3: Existing Implementation Inventory (MANDATORY)

**This step is REQUIRED. File paths alone are NOT sufficient.**

For each related file identified:
1. **Actually Read the file** using Read tool
2. **Extract implementation summary**:
   - Main exported functions/classes
   - Key type definitions
   - External dependencies
   - Current functionality

```markdown
## Implementation Inventory

| File | Status | Key Exports | Summary |
|------|--------|-------------|---------|
| path/to/file.ts | Read | funcA, funcB | [what it does] |
```

**Red Flags - STOP if you catch yourself:**
- "I'll just list the file paths" → NO. Read each file.
- "The file name suggests..." → NO. Read the actual content.
- "Based on the directory structure..." → NO. Read the files.

### Step 4: Diff Analysis (for multi-app/multi-module tasks)

When multiple implementations exist:

```markdown
## Diff Analysis

| Feature | App A | App B | App C | Status |
|---------|-------|-------|-------|--------|
| Feature X | uses shared | custom impl | not present | Needs migration |
| Feature Y | shared | shared | shared | Already unified |
```

**Classification:**
- **Unified**: Already using shared implementation
- **Needs migration**: Custom implementation that should migrate to shared
- **App-specific**: Intentionally different per app (document why)

### Step 5: Dependency Analysis (for existing-modification)

**This step is REQUIRED for existing-modification mode.**

#### Procedure:

**Step 1: 変更対象ファイルの特定**
```bash
# Grep/Glob で変更対象を特定
Grep pattern="function_name|class_name"
```

**Step 2: 呼び出し元の特定**
```bash
# 変更対象の関数/クラスがどこで使用されているか
Grep pattern="import.*{function_name}" output_mode="files_with_matches"
Grep pattern="function_name\(" output_mode="content"
```

**Step 3: 呼び出し先の特定**
```
# 変更対象ファイルをReadして、import文から呼び出し先を特定
Read: [target file]
# import文を解析して依存先をリストアップ
```

**Step 4: テストの特定**
```bash
# 関連テストを検索
Glob pattern="**/*.test.{ts,tsx}"
Grep pattern="function_name|class_name" glob="**/*.test.{ts,tsx}"
```

#### Impact Map Template:

```markdown
## Impact Map (existing-modification)

### 変更対象ファイル
| ファイル | 変更内容 | 理由 |
|---------|---------|------|
| path/to/file.ts | 関数Aの修正 | バグ修正 |

### 依存関係グラフ
[変更対象]
path/to/file.ts (関数A)
  ↑ 呼び出し元
  ├── src/pages/xxx.tsx
  ├── src/components/xxx.tsx
  └── apps/xxx/pages/index.tsx
  ↓ 呼び出し先
  ├── src/db/xxx.ts
  └── src/utils/xxx.ts

### 影響範囲
| アプリ/機能 | 影響度 | 理由 |
|-----------|-------|------|
| xxx アプリ | 高 | 直接使用 |
| yyy アプリ | 低 | 使用していない |

### 既存テスト
| テストファイル | 影響 | 対応 |
|-------------|------|------|
| xxx.test.ts | あり | 更新必須 |
| yyy.test.ts | なし | 追加検討 |
```

### Step 6: 整合性チェックリストへの活用

Impact Mapの結果は、Phase 3（design）の整合性チェックリストで活用する:

| Impact Map項目 | 整合性チェックリスト項目 |
|---------------|----------------------|
| 変更対象ファイル | API整合性 → 変更対象API |
| 依存関係グラフ | DBスキーマ整合性 → 影響テーブル |
| 既存テスト | テスト整合性 → 更新必須テスト |
| 影響範囲 | 破壊的変更判定 → 影響アプリ |

この結果を `docs/investigation/{workflow-id}-impact.md` に保存し、
Phase 3で参照する。

### Step 7: Results Integration
- Document investigation results
- Identify reusable code/patterns
- Decide: componentize vs standalone implementation

### Step 8: Chrome挙動確認（オプショナル、existing-modificationモードのみ）

**実行条件:**
- `mode: "existing-modification"` かつ `chromeInvestigation: true` の場合のみ実行
- いずれかが満たされない場合は **完全にスキップ** する

**Phase 2 vs Phase 6 の差異:**

| 観点 | Phase 2（本ステップ） | Phase 6（Chromeデバッグ） |
|------|---------------------|--------------------------|
| 目的 | 修正前のベースライン記録 | 実装後の動作検証 |
| 操作 | Read-only観察のみ | インタラクション含む検証 |
| 修正サイクル | なし | 最大3回の修正→再検証 |
| ゲート条件 | なし（情報収集のみ） | コンソールエラーゼロが必須 |
| 対象 | 変更予定の既存画面 | 実装した新規/修正済み画面 |

**実行手順:**

親エージェントがdevサーバーを起動した後、サブエージェントに観察を委譲する。
devサーバー起動は `chrome-debug` スキルの Step 1 と同様のパターンを使用する。

````
Task(subagent_type="general-purpose", model="sonnet"):
  ## Phase 2: Chrome挙動確認（Read-only観察）

  ### 目的
  修正前の既存UIの現在の挙動を記録する。修正後の比較ベースラインとして使用する。
  ★操作・修正は一切行わないこと（Read-onlyのみ）

  ### 対象URL
  http://localhost:[PORT]/[変更対象の画面パス]

  ### 観察項目

  #### A. 画面表示確認
  1. tabs_context_mcp でタブ情報を取得
  2. navigate で対象ページを開く
  3. computer(action="screenshot") で現在の表示状態を記録
  4. get_page_text で表示テキストを記録

  #### B. コンソールログ確認
  1. read_console_messages(pattern="Error|Warning") で既存エラーを記録

  #### C. ネットワーク確認
  1. read_network_requests で既存APIコールパターンを記録

  ### 報告形式
  ## Chrome挙動確認結果（修正前ベースライン）
  - 対象画面: [URL]
  - 表示状態: [正常/問題あり（詳細）]
  - 既存コンソールエラー: [0件 / N件（内容）]
  - 既存ネットワークエラー: [0件 / N件（内容）]
  - 観察した挙動: [箇条書き]
  - Phase 6での注意点: [修正時に考慮すべき点]
````

**スキップ時の記録:**
`chromeInvestigation: false` の場合は以下のみ記録して次へ進む:
```
## Chrome挙動確認: スキップ
理由: questioningフェーズでスキップを選択
```

## Results Format

```markdown
## Investigation Results: [Topic]

### Implementation Inventory (REQUIRED)

| File | Exported | Summary |
|------|----------|---------|
| path/file.ts:L10-50 | createFoo() | Creates Foo with validation |

### Diff Analysis (if applicable)

| Feature | Location A | Location B | Status |
|---------|-----------|-----------|--------|
| X | custom | shared | Needs migration |

### Reusable Utilities
- [utility name] (path:line): [usage method]

### Technical Constraints
- [constraint description]

### Risks
- [risk description and mitigation]

### What Exists vs What's Needed
| Capability | Exists? | Location | Gap |
|------------|---------|----------|-----|
| OCR extraction | Yes | pkg/ocr.ts:L20 | PDF not supported |
```

## Completion Criteria

### Common (all modes)
- [ ] All related existing code identified
- [ ] **Each file ACTUALLY READ (not just listed)**
- [ ] **Implementation summary for each file documented**
- [ ] Reusable utilities listed with exact paths
- [ ] Technical constraints/risks documented
- [ ] External dependency specs confirmed
- [ ] **Diff analysis completed (for multi-app tasks)**
- [ ] **Exists vs Needed gap analysis documented**

### Additional for existing-modification mode
- [ ] **変更対象ファイルの完全読み込み完了**
- [ ] **呼び出し元の特定完了**
- [ ] **呼び出し先の特定完了**
- [ ] **影響範囲マップ作成完了**
- [ ] **既存テストの棚卸し完了**

### Optional for existing-modification mode
- [ ] **Chrome挙動確認実施済み**（`chromeInvestigation: true` の場合のみ）
  - 対象画面の表示状態を記録
  - 既存コンソールエラーを記録
  - 既存ネットワークエラーを記録

### Verification Mechanism (必須)

完了条件を自己申告に依存させない。以下の検証を実行:

#### 1. Inventory形式検証
```
## 検証チェック
| 検証項目 | 結果 | 証拠 |
|---------|------|------|
| Key Exports列が空の行がない | Pass/Fail | 該当行数 |
| Statusが「Read」以外の行がない | Pass/Fail | 該当行数 |
| Summary列が「TBD」「-」の行がない | Pass/Fail | 該当行数 |
```

#### 2. 不合格時の処理
- **1件でもFail**: Phase 3へ進行不可
- **差し戻し条件**: 以下のいずれかに該当する場合は却下
  - 「ファイル名から推測」「ディレクトリ構造から推測」等の憶測
  - 根拠不足: path:line参照・コマンド実行結果が欠けている
- **注意**: Chrome挙動確認（Step 8）はオプショナルのため、未実施でも不合格にしない

#### 3. 証拠の最小要件
各ファイルの調査には以下を必須とする:
- `path:line` 形式のコード参照
- 実際に実行したコマンド（Glob/Grep/Read）
- コマンドの出力結果の要約
