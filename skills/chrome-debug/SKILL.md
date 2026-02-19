---
name: chrome-debug
description: 実装完了後、ChromeブラウザでUIと挙動を実際に検証するPhase 6スキル
---

# Chrome Debug Phase

## Overview

Phase 6として、Phase 5（実装）の後、Phase 7（コードレビュー）の前に実行する。

ChromeのMCPツールを使って実際のUIと挙動を検証する。自動テストでは検出できないUIバグ、レイアウト崩れ、インタラクションの問題を発見するためのPhase。全タスクで必須。

**位置づけ:**
```
Phase 5（実装）→ Phase 6（Chrome検証）→ Phase 7（コードレビュー）→ Phase 8（テスト）
```

## The Iron Law

```
IMPLEMENTATION DONE != BROWSER VERIFIED
ZERO CONSOLE ERRORS IS THE GATE
NO BROWSER CHECK = NO NEXT PHASE
```

- 実装コードを書き終えたら必ずブラウザで動作確認する
- コンソールエラーゼロが次Phase遷移の条件
- 問題発見時は自動修正→再検証（最大3回）

## Prerequisites

- Phase 5（実装）が完了していること
- Chrome拡張（claude-in-chrome）がアクティブであること
- devサーバーが起動可能であること

## Execution Model

**Chrome操作は必ずサブエージェント（sonnet）に委譲する。**

親エージェントはオーケストレーションのみを担当し、実際のブラウザ操作はサブエージェントが実行する。
これにより親エージェントのコンテキストを汚さず、Chrome操作の詳細を隔離できる。

```
Task(subagent_type="fractal-dev-workflow:chrome-debugger", model="sonnet"):
  ## Phase 6: Chromeデバッグ

  ### 対象URL
  http://localhost:[PORT]/[パス]

  ### 検証項目
  1. UI表示確認（主要画面）
  2. インタラクション検証（フォーム、ボタン）
  3. エラー検出（コンソール、ネットワーク）

  ### 報告形式
  - 検証した画面一覧
  - 発見した問題（あれば）
  - コンソールエラーの有無
  - ネットワークエラーの有無
```

## The Process

```
環境準備（親） → Chrome検証（サブエージェント） → 問題修正（サブエージェント） → 再検証
```

---

## Step 1: 環境準備（親エージェントが実行）

```bash
# 1. devサーバーを起動
#    ポート3100を試行、使用中なら3101-3199でフォールバック
PORT=$(find_available_port)  # 後述のポート管理関数を使用
npm run dev -- --port $PORT

# ポート使用状況確認
lsof -i :3100
```

---

## Step 2-4: Chrome検証（サブエージェントが実行）

親エージェントは以下のようにサブエージェントを起動する:

```
Task(subagent_type="fractal-dev-workflow:chrome-debugger", model="sonnet"):
  ## Chrome UIデバッグ検証

  ### 環境
  - URL: http://localhost:${PORT}
  - 対象画面: [Phase 1で定義した主要画面リスト]

  ### Step 2: UI表示確認
  以下のChrome MCPツールを使用して検証してください:

  1. tabs_context_mcp でブラウザ状態確認
  2. tabs_create_mcp で新規タブ作成
  3. navigate で対象ページを開く
  4. get_page_text で表示テキスト確認
     - 期待するテキストが表示されているか
     - 文字化け、レイアウト崩れがないか
  5. find で主要要素の存在確認
     - フォーム要素、ボタン、ナビゲーション
  6. read_page でHTML構造確認（必要な場合）

  ### Step 3: インタラクション検証
  1. form_input でフォーム入力テスト
     - 正常値での入力
     - バリデーション動作確認
  2. computer でクリック・ナビゲーション操作
     - ボタンクリック後の状態変化
     - ページ遷移の確認
  3. get_page_text で操作後の状態変更を確認

  ### Step 4: エラー検出
  1. read_console_messages(pattern="Error|Uncaught|Warning") でJS問題確認
  2. read_network_requests でAPIコール確認
     - 4xx/5xx レスポンスの検出
  3. javascript_tool で状態確認（必要な場合）

  ### 報告形式
  以下の形式で結果を報告:
  - 検証した画面: [一覧]
  - UI表示: OK / NG（詳細）
  - インタラクション: OK / NG（詳細）
  - コンソールエラー: 0件 / N件（内容）
  - ネットワークエラー: 0件 / N件（内容）
  - 発見した問題: [リスト]
```

---

## Step 5: 問題修正サイクル（問題発見時のみ）

サブエージェントから問題レポートを受け取った場合:

```
1. 問題を分類
   - UIバグ（CSS/HTML）
   - ロジックバグ（JavaScript）
   - APIエラー（バックエンド）

2. 修正用サブエージェントを起動
   Task(subagent_type="fractal-dev-workflow:coder", model="sonnet"):
     [問題の詳細と修正指示]

3. 再検証用サブエージェントを起動（Step 2-4を再実行）
   Task(subagent_type="fractal-dev-workflow:chrome-debugger", model="sonnet"):
     [再検証指示]

4. 最大3回まで繰り返し

5. 3回で解決しない場合:
   - 問題レポートを作成
   - 次Phaseへ遷移（問題を記録して継続）
```

---

## Chrome MCP ツールリファレンス

| カテゴリ | ツール | 用途 |
|---------|--------|------|
| 基本確認 | navigate | ページ遷移 |
| 基本確認 | get_page_text | テキスト取得 |
| 基本確認 | find | 要素検索 |
| 基本確認 | read_page | HTML取得 |
| 操作 | form_input | フォーム入力 |
| 操作 | computer | クリック・キー入力 |
| エラー検出 | read_console_messages | コンソールログ |
| エラー検出 | read_network_requests | ネットワーク監視 |
| 補助 | javascript_tool | JS実行 |
| 補助 | tabs_context_mcp | タブ状態 |
| 補助 | tabs_create_mcp | タブ作成 |
| 記録 | gif_creator | 操作記録GIF |
| 記録 | resize_window | ウィンドウリサイズ |

---

## Dev Server Port Management

```bash
# ポートフォールバックロジック
find_available_port() {
  for port in $(seq 3100 3199); do
    if ! lsof -i :$port > /dev/null 2>&1; then
      echo $port
      return 0
    fi
  done
  echo "ERROR: No available port in 3100-3199 range" >&2
  return 1
}

# 使用例
PORT=$(find_available_port)
npm run dev -- --port $PORT
```

---

## Completion Criteria

- [ ] 全主要画面を表示確認
- [ ] 全主要インタラクションを実行確認
- [ ] コンソールにJSエラーがゼロ
- [ ] ネットワークリクエストに4xx/5xxがゼロ
- [ ] 問題発見時: 修正済みまたはレポート作成済み

---

## Red Flags

| Thought | Reality |
|---------|---------|
| "ブラウザ確認は不要" | 全タスク必須 |
| "テストが通っているから大丈夫" | テストでは検出できないUIバグがある |
| "コンソールの警告は無視" | 警告も確認対象 |
| "devサーバーが起動しない" | ポートフォールバックを使え |
| "Chrome拡張が動かない" | セットアップを確認してから進行 |

---

## Related Skills

- `implementation` - Phase 5（前Phase）
- `codex-review` - Phase 7（後Phase）
- `verification` - Phase 8（テスト）
- `dev-workflow` - メインオーケストレーター
