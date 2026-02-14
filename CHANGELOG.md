# Changelog

## [Unreleased]

### Added

- 8フェーズワークフローシステム (Phase 1-8)
- 2段階承認機能 (`approve` 関数)
  - Codex承認: `approve <workflow_id> <phase> "codex"`
  - User承認: `approve <workflow_id> <phase>` (デフォルト)
- Phase 4 (計画レビュー) の2段階承認チェック
- Phase 6 (コードレビュー) の2段階承認チェック
- テストスイート (`tests/test-workflow-approval.sh`)
- テスト実行ガイド (`tests/README.md`)

### Changed

- ワークフローフェーズを6から8に拡張
  - Phase 1: 質問
  - Phase 2: 調査
  - Phase 3: 設計 (旧: 計画)
  - Phase 4: 計画レビュー (新規)
  - Phase 5: 実装
  - Phase 6: コードレビュー (新規)
  - Phase 7: テスト (新規)
  - Phase 8: 運用設計 (旧: Phase 6)
- `record_approval` 関数を `approve` に名称変更 (後方互換性維持)
- 承認フィールド名の変更
  - 旧: `approvedAt`
  - 新: `codexApprovedAt` / `userApprovedAt`
- `check-approval.sh` の承認チェックロジックを2段階承認に対応

### Fixed

- Phase 3 の承認チェックが `userApprovedAt` を参照するように修正

## [0.1.0] - 2026-02-14

### Added

- 初回リリース
- 基本的な6フェーズワークフロー
- Codex統合
- サブエージェントシステム
