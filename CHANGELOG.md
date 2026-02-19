# Changelog

## [Unreleased]

## [0.10.5] - 2026-02-20

### Fixed

- スキルファイル内のスクリプト参照を絶対パス（`~/.claude/plugins/local/fractal-dev-workflow/scripts/`）に統一 - worktreeや別ディレクトリからの実行時にスクリプトが見つからないエラーを解消
- check-docs.shのバージョンバンプ時に`installed_plugins.json`のinstallPathとキャッシュシンボリックリンクも即時同期するよう修正（SessionEnd待ちの不整合を解消）

## [0.10.3] - 2026-02-19

### Fixed

- chrome-debuggerエージェントにChrome MCPツール（mcp__claude-in-chrome__*）を追加 - ブラウザ操作が実行できない問題を修正

## [0.10.1] - 2026-02-19

### Fixed

- コンテキストドキュメント更新・CHANGELOG整合性修正

## [0.8.0] - 2026-02-19

### Added

- workflow-manager.shにTasks連携コマンド追加（`tasks`/`add-task`/`update-task`）
- design/SKILL.mdにClaude Code TaskCreate/TaskUpdate具体例追加
- implementation/SKILL.mdにStrategy A/Bタスク進捗管理セクション追加
- dev-workflow/SKILL.mdにPhase 3/5のTasks完了条件追加
- plugin-auditスキルを日本語・マーメイド図3種類付きレポート出力に改修
- 監査レポートの日付管理（`docs/audits/YYYY-MM-DD.md`）
- テスト追加: test-hook-scripts.sh新規、test-workflow-approval.shエッジケース4件

### Fixed

- [C-1] workflow-manager.sh: create_workflow()のJSONインジェクション脆弱性修正（jq -n --arg使用）
- [I-1] codex-wrapper.sh: run_with_retry()の終了コード消失修正
- [I-2] hooks.json: SessionEndフックにreinstall-plugin.sh登録
- [F-1] dev-status.md: フェーズ番号修正（4 and 6 → 4 and 7）
- [F-2] using-workflow/SKILL.md: 存在しないスキル名・Phase名を仕様に整合
- [F-3] marketplace.json: バージョン0.8.0・9フェーズ説明に更新
- [M-1] reinstall-plugin.sh: ハードコードパスをスクリプト位置解決に変更

### Changed

- workflow-manager.sh: RANDOM ID生成を連番方式に改善（衝突回避）
- chrome-debugger.md: toolsフロントマター追加
- test-plugin-audit-skill.sh: 日本語化対応のテストパターン修正

## [0.7.0] - 2026-02-19

### Added

- workflow-manager.shに`get-dir`コマンド追加（worktreeスコープのワークフローディレクトリパス取得）
- plugin-auditレポートをMermaid図付きmdファイル（`docs/audit-report.md`）として出力

### Fixed

- SKILL.md内のハードコードパス（`~/.claude/fractal-workflow/`）をworkflow-manager.sh経由に修正
  - 対象: dev-workflow, using-workflow, design, failure-memory, implementation

## [0.6.0] - 2026-02-19

### Added

- plugin-auditスキル（5カテゴリ評価: Structure, Compliance, Flow, Token, Security）
  - 100点満点のスコア付きレポート生成
  - サブエージェント並列評価による客観性確保
  - 証拠ベース評価（path:line必須、推測禁止）
  - スコアリング基準定義 (references/scoring-rubric.md)
  - 仕様準拠チェックルール定義 (references/compliance-rules.md)
- /plugin-auditコマンド追加

### Fixed

- workflow-manager.shのWORKFLOW_DIRパス解決を修正（get_workflow_dir()に統一）
- codex-wrapper.shのtimeout実装をmacOS互換に置換（バックグラウンドプロセス+手動タイムアウト管理）

## [0.4.0] - 2026-02-17

### Added

- モード分岐ロジック (new-creation / existing-modification)
- 用語定義セクション (Source of Truth) - dev-workflow/SKILL.md
- 検証メカニズム強化
  - Inventory形式検証 (Key Exports/Status/Summary)
  - 差し戻し条件: 「ファイル名から推測」「根拠不足」は却下
  - 証拠の最小要件: path:line + コマンド + 結果
- 破壊的変更判定ロジック (design/SKILL.md)
- PR作成前ゲートチェック (completion/SKILL.md)
- code-simplifier統合 (各Slice完了後に自動実行)
- コミット前チェック自動化 (pnpm test/lint/typecheck)
- Worktree Enforcement (Phase 5開始時に必須)
- 追加要望対応フロー (質問→調査→判定→実装)
- コンテキスト保存戦略 (コミットメッセージに作業状態を構造化記録)
- doc-reviewerエージェント
- context-preservationスキル
- post-mergeスキル群 (post-merge-tasks, post-merge-execute)
- plugin-reinstallスキル
- ワークフローフロードキュメント (docs/workflow-flow.md) - Mermaid図
- ドキュメント更新スキル (update-docs) - バージョン管理ルール付き
- pre-pushドキュメントチェックフック (hooks/check-docs.sh)
- update-docsコマンド
- Phase終了時のmemory記録トリガー
- compact後のサブエージェント駆動開発継続機能

### Changed

- Codexレビュー (Phase 4/6) の承認フローを自動遷移に変更
  - Phase 4→5: Critical Issuesがあっても自動修正→自動遷移
  - Phase 6→7: Critical Issuesがあっても自動修正→自動遷移
- Phase 3→4: ユーザー承認必須 (全モード共通)
- Codexレビューを必須化 (スキップ不可)
- Codex利用不可時のフォールバックをqaエージェントに統一
- staff-reviewer参照を全てqaエージェントに置換
- NEEDS_CHANGES時の再レビューフロー簡素化 (最大3回→自動遷移)
- codex-reviewにVerdictの重大/軽微判定基準を追加
- サブエージェント名の統一
- investigation差し戻し条件に「根拠不足」を追加

### Fixed

- Codexレビュー (Phase 4/6) がスキップされる問題を修正
  - Phase遷移トリガーの例示を必須命令に強化
  - Completion Criteriaにcodex-delegate起動を明記
  - フォールバック処理の未実装を修正
  - スキップ可能な遷移条件を削除
- codex-wrapper.shのフォールバック参照を修正 (staff-reviewer → qa)
- フローチャートとPhase Transition Rulesの不一致を修正
- designスキルの完了条件をモード別に分離

### Removed

- Codexレビュー時のユーザー承認ゲート (Phase 4→5, 6→7)
- staff-reviewerエージェント参照
- 不要なドキュメント (design-dev-workflow-v2.md, phase-4/6レビューレポート)

## [0.3.0] - 2026-02-14

### Added

- 8フェーズワークフロー（運用設計Phaseを独立化）
- 2段階承認機能（Codex承認→ユーザー承認）
- 承認チェックとフェーズ遷移ガード
- designスキルにタスク分解とworktree計画を追加
- 質問フェーズのサブエージェント駆動を明示化

### Changed

- 7フェーズ → 8フェーズに拡張（検証と運用設計を分離）
- 入力検証の強化とドキュメント統一

### Fixed

- hooks.jsonの形式をnested形式に修正

## [0.2.0] - 2026-02-12

### Added

- dev-workflowオーケストレータースキル（7フェーズ）
- コアスキル: questioning, investigation, planning, codex-review, implementation
- 補助スキル: failure-memory, parallel-implementation, context-circulation, testing
- エージェント: investigator, code-reviewer, implementer, codex-delegate, staff-reviewer, spec-reviewer, QA, Coder
- Codexラッパースクリプト (codex-wrapper.sh)
- ワークフローヘルパースクリプト
- フックシステム（承認強制）
- カスタムコマンド (/dev, /dev-status, /dev-resume)
- マーケットプレイス構造
- Codex 5.3 + 2観点レビュー導入
- TDDワークフロー統合
- Asai-Spec Protocol（エージェント役割分担）
- Sonnet 4.5積極活用方針
- README.md、using-workflowスキル
- セットアップ手順、権限設定の配布方法

### Changed

- 6フェーズ → 7フェーズに拡張（調査・計画フェーズを強化）

### Fixed

- codex-wrapper.shのCLI引数を環境変数に修正
- codex-delegate.mdの形式修正

## [0.1.0] - 2026-02-12

### Added

- プラグイン基盤作成 (plugin.json、ディレクトリ構造)
- 基本的な6フェーズワークフロー
- Codex統合
- サブエージェントシステム基盤
