# fractal-dev-workflow

フェーズ単位承認型の自律開発支援プラグイン for Claude Code。

## 特徴

- **8フェーズワークフロー**: 質問→調査→契約設計→Codex計画レビュー→実装→Codexコードレビュー→検証→運用設計
- **承認ゲート**: Phase 4（Codex計画レビュー）とPhase 6（Codexコードレビュー）で Codex承認→ユーザー承認
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
Phase 3: 計画 (Planning)
    ↓ ★ユーザー承認必須★
Phase 4: 批判的レビュー (Critical Review)
    ↓ 自動
Phase 5: 実装 (Implementation)
    ↓ ★ユーザー承認必須★
Phase 6: 完了 (Completion)
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
| `using-workflow` | 使用ガイド |

## エージェント一覧

| エージェント | モデル | 役割 |
|-------------|--------|------|
| `spec-reviewer` | Sonnet | 仕様準拠レビュー |
| `code-reviewer` | Sonnet | コード品質レビュー |
| `investigator` | Haiku | コードベース調査 |
| `implementer` | Sonnet | コード実装 |
| `codex-delegate` | Haiku | Codex CLI呼び出し |
| `staff-reviewer` | Opus | Codexフォールバック |

## 依存関係

- Claude Code CLI
- jq (JSON処理)
- bash 4.0+
- flock (ファイルロック)
- Codex CLI (オプション、なければstaff-reviewerで代替)

## 設定

### 環境変数

```bash
WORKFLOW_DIR     # ワークフロー状態保存先 (default: ~/.claude/fractal-workflow)
CODEX_TIMEOUT    # Codex実行タイムアウト秒 (default: 300)
MAX_RETRIES      # Codexリトライ回数 (default: 2)
```

## ライセンス

MIT
