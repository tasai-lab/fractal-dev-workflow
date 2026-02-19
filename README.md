# fractal-dev-workflow

フェーズ単位承認型の自律開発支援プラグイン for Claude Code。

## 特徴

- **9フェーズワークフロー**: 質問→調査→設計→計画レビュー→実装→Chromeデバッグ→コードレビュー→テスト→完了
- **Codex自動レビュー**: Phase 4(計画レビュー)とPhase 7(コードレビュー)でCodexによる批判的レビューを自動実行。レビュー結果に関わらず自動遷移
- **Codexレビュー統合**: 外部の批判的視点で品質保証
- **チーム駆動実装**: サブエージェントによる並列実装
- **失敗パターン学習**: 同じ失敗を繰り返さない

## インストール

```bash
# Claude Codeのプラグインマネージャーからインストール
/plugin install fractal-dev-workflow

# または、手動でクローン
cd ~/.claude/plugins
git clone https://github.com/tasai-lab/fractal-dev-workflow.git
```

### セットアップ（初回のみ）

Codex レビュー機能を使用するには、`scripts/codex-wrapper.sh` の実行権限が必要です。
プロジェクトの `.claude/settings.local.json` に以下を追加してください:

```json
{
  "permissions": {
    "allow": [
      "Bash(scripts/codex-wrapper.sh:*)"
    ]
  }
}
```

**注意**: 相対パス `scripts/codex-wrapper.sh` はプラグインディレクトリからの相対パスです。

## 使用方法

### 基本コマンド

```bash
/dev [タスク説明]  # 新規ワークフロー開始
/dev resume        # 中断されたワークフローを再開
/dev status        # 現在の状態を表示
/dev cancel        # ワークフローをキャンセル
```

### ワークフローの流れ

```
Phase 1: 質問 (Questioning)
    ↓ 自動
Phase 2: 調査 (Investigation)
    ↓ 自動
Phase 3: 設計 (Design)
    ↓ 自動遷移
Phase 4: 計画レビュー (Plan Review)
    ↓ Codex自動レビュー→自動遷移
Phase 5: 実装 (Implementation)
    ↓ 自動
Phase 6: Chromeデバッグ (Chrome Debug)
    ↓ 自動
Phase 7: コードレビュー (Code Review)
    ↓ Codex自動レビュー→自動遷移
Phase 8: テスト (Testing)
    ↓ 自動
Phase 9: 完了 (Completion)
```

## スキル一覧

| スキル | 説明 |
|--------|------|
| `dev-workflow` | メインオーケストレーター |
| `questioning` | Phase 1: 要件の明確化 |
| `investigation` | Phase 2: コードベース調査 |
| `planning` | Phase 3: 実装計画策定 |
| `codex-review` | Phase 4: Codex批判的レビュー |
| `implementation` | Phase 5: サブエージェント駆動実装 |
| `failure-memory` | 失敗パターンの記録・学習 |
| `parallel-implementation` | 並列実装設計 |
| `context-circulation` | コミットによるコンテキスト共有 |
| `context-preservation` | compact後のコンテキスト保存・復元 |
| `using-workflow` | 使用ガイド |
| `plugin-audit` | プラグイン品質評価（5カテゴリ・100点満点） |

## エージェント一覧

| エージェント | モデル | 役割 |
|-------------|--------|------|
| `spec-reviewer` | Sonnet | 仕様準拠レビュー |
| `code-reviewer` | Sonnet | コード品質レビュー |
| `investigator` | Haiku | コードベース調査 |
| `implementer` | Sonnet | コード実装 |
| `codex-delegate` | Haiku | Codex CLI呼び出し |
| `qa` | Sonnet | Codexフォールバック（レビュー必須） |
| `doc-reviewer` | Sonnet | ドキュメント品質レビュー |

## 依存関係

- Claude Code CLI
- jq (JSON処理)
- bash 4.0+
- flock (ファイルロック)
- Codex CLI (推奨、なければqaエージェントでフォールバック。レビュー自体は必須)

## 設定

### 環境変数

```bash
WORKFLOW_DIR     # ワークフロー状態保存先 (default: ~/.claude/fractal-workflow)
CODEX_TIMEOUT    # Codex実行タイムアウト秒 (default: 300)
MAX_RETRIES      # Codexリトライ回数 (default: 2)
```

## ライセンス

MIT
