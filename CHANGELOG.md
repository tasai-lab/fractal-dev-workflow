# Changelog

## [Unreleased]

### Added

- 8フェーズワークフローシステム (Phase 1-8)
- Codex計画レビュー (Phase 4) - codex-delegate + xhigh reasoning
- Codexコードレビュー (Phase 6) - コード品質・セキュリティ自動検証
- サブエージェント駆動開発
  - investigator: コードベース調査
  - architect: 設計・仕様作成
  - tech-lead: タスク分解
  - coder: TDD実装
  - qa: 品質検証（読み取り専用）
  - codex-delegate: Codex CLI呼び出し
  - code-simplifier: コード簡素化
  - doc-reviewer: ドキュメント品質レビュー
- モード分岐ロジック (new-creation / existing-modification)
- 用語定義セクション (Source of Truth) - dev-workflow/SKILL.md
- 検証メカニズム強化
  - Inventory形式検証 (Key Exports/Status/Summary)
  - 差し戻し条件: 「ファイル名から推測」は却下
  - 証拠の最小要件: path:line + コマンド + 結果
- 破壊的変更判定ロジック (design/SKILL.md)
  - 定義表 (API/DB/認証/設定)
  - jqコマンドによるstate記録
  - 4ステップ判定フロー
- PR作成前ゲートチェック (completion/SKILL.md)
- code-simplifier統合 (各Slice完了後に自動実行)
- コミット前チェック自動化 (pnpm test/lint/typecheck)
- Worktree Enforcement (Phase 5開始時に必須)
- 追加要望対応フロー (質問→調査→判定→実装)
- コンテキスト保存戦略 (コミットメッセージに作業状態を構造化記録)
- failure-memoryスキル (失敗パターン記録・再発防止)
- context-circulationスキル (コミット経由のコンテキスト共有)
- ワークフローフロードキュメント (docs/workflow-flow.md)

### Changed

- 全承認フローを自動遷移に変更 (ユーザー承認不要)
  - Phase 3→4: モードに関わらず自動遷移
  - Phase 4→5: Critical Issuesがあっても自動修正→自動遷移
  - Phase 6→7: Critical Issuesがあっても自動修正→自動遷移
- Codexレビューを必須化 (スキップ不可)
- Codex利用不可時のフォールバックをqaエージェントに統一
- staff-reviewer参照を全てqaエージェントに置換
- Phase概要テーブルのApproval列を更新 (Phase 4/6: Auto)
- NEEDS_CHANGES時の再レビューフロー簡素化 (最大3回→自動遷移)
- planningスキルの承認セクションを自動遷移に変更

### Fixed

- Codexレビュー (Phase 4/6) がスキップされる問題を修正
  - Phase遷移トリガーの例示を必須命令に強化
  - Completion Criteriaにcodex-delegate起動を明記
  - フォールバック処理の未実装を修正
  - スキップ可能な遷移条件を削除
- codex-wrapper.shのフォールバック参照を修正 (staff-reviewer → qa)
- フローチャートとPhase Transition Rulesの不一致を修正
- Phase 3のnew-creation/breaking changes承認とTransition Rulesの矛盾を修正

### Removed

- ユーザー承認ゲート (Phase 3→4, 4→5, 6→7)
- staff-reviewerエージェント参照
- 2段階承認機能の記述

## [0.1.0] - 2026-02-14

### Added

- 初回リリース
- 基本的な6フェーズワークフロー
- Codex統合
- サブエージェントシステム
