# コンテキストドキュメント

最終更新: 2026-02-20（299524d）

## 現在の状態

- **Phase**: Phase 8（検証）完了、全16タスク完了、全テスト合格（66/66）
- **進行中タスク**: なし（安定稼働中）
- **バージョン**: 0.11.1（push時にconventional commitsで自動バンプ）

## 実装経緯テーブル

| コミットハッシュ | 日付 | 内容 | 影響範囲 |
|---|---|---|---|
| 299524d | 2026-02-20 | chore: bump version to 0.11.1 | .claude-plugin/plugin.json, CHANGELOG.md |
| e654f11 | 2026-02-20 | docs(context): コンテキストドキュメント更新 - ワークフロー保存先を .git/fractal-workflow/ に変更 | docs/context/CONTEXT.md |
| bae3896 | 2026-02-20 | fix: ワークフロー保存先をリポジトリの .git/fractal-workflow/ に変更 | hooks/workflow-lib.sh, scripts/workflow-manager.sh |
| 4c63c5b | 2026-02-20 | docs(context): コンテキストドキュメント更新 - 自律判断原則追加・Chrome調査の自律化 | docs/context/CONTEXT.md |
| 6305b15 | 2026-02-20 | chore: bump version to 0.11.0 | .claude-plugin/plugin.json |
| 0bf2797 | 2026-02-20 | feat: 自律判断原則追加・Chrome調査の自律化 | skills/dev-workflow/SKILL.md, skills/questioning/SKILL.md |
| 191cf8a | 2026-02-20 | docs(context): コンテキストドキュメント更新 - v0.10.9リリース | docs/context/CONTEXT.md |
| 3efe125 | 2026-02-20 | docs: CHANGELOG更新 - v0.10.9 | CHANGELOG.md |
| c0948ed | 2026-02-20 | chore: bump version to 0.10.9 | .claude-plugin/plugin.json |
| 4645d59 | 2026-02-20 | docs(context): コンテキストドキュメント更新 - Chrome deferred toolsロード・UIタスクリスト自動作成 | docs/context/CONTEXT.md |
| a10b2df | 2026-02-20 | fix: Chrome deferred toolsロード・UIタスクリスト自動作成を追加 | agents/chrome-debugger.md, skills/chrome-debug/SKILL.md, skills/dev-workflow/SKILL.md |
| c79c2df | 2026-02-20 | chore: bump version to 0.10.8 | .claude-plugin/plugin.json |
| 9b8d1e6 | 2026-02-20 | docs(context): コンテキストドキュメント更新 - check-docs.shスコープ修正 | docs/context/CONTEXT.md |
| 856cfc2 | 2026-02-20 | fix(hooks): check-docs.shをプラグインリポジトリ内のみに限定 | hooks/check-docs.sh |
| e0ee416 | 2026-02-20 | chore: bump version to 0.10.6 | .claude-plugin/plugin.json |
| 45e9494 | 2026-02-20 | docs(context): コンテキストドキュメント更新 - バージョンバンプ時のシンボリックリンク同期 | docs/context/CONTEXT.md |
| 49a59fc | 2026-02-20 | fix(hooks): バージョンバンプ時にinstallPathとキャッシュシンボリックリンクも同期 | hooks/check-docs.sh, CHANGELOG.md |
| 9a37e0f | 2026-02-20 | chore: bump version to 0.10.4 | .claude-plugin/plugin.json |
| 9222849 | 2026-02-20 | fix(skills): スクリプト参照を絶対パスに統一しworktree独立性を確保 | skills/codex-review, skills/design, skills/dev-workflow, skills/failure-memory, skills/implementation, skills/investigation, skills/planning, skills/plugin-reinstall, skills/post-merge-execute, skills/using-workflow |
| 7890e7b | 2026-02-20 | fix: プラグイン再インストールの自動化を強化 | hooks/ |
| 7e5e22e | 2026-02-20 | fix: .claude-plugin/plugin.jsonの空ファイルを修復 | .claude-plugin/plugin.json |
| cf5d79d | 2026-02-20 | chore: bump version to 0.10.3 | .claude-plugin/plugin.json |
| 1f566d7 | 2026-02-19 | fix(agent): chrome-debuggerにChrome MCPツールを追加 | agents/chrome-debugger.md |
| 822f3fd | 2026-02-19 | chore: bump version to 0.10.2 | .claude-plugin/plugin.json |
| b0881f0 | 2026-02-19 | chore: bump version to 0.10.2 | .claude-plugin/plugin.json |
| 5506c7e | 2026-02-19 | docs(context): コンテキストドキュメント更新 - v0.10.1 | docs/context/CONTEXT.md |
| 443db7d | 2026-02-19 | docs: CHANGELOG.md更新 - v0.10.1 整合性修正 | CHANGELOG.md |
| 4a01678 | 2026-02-19 | chore: bump version to 0.10.1 | .claude-plugin/plugin.json |
| 0823ae8 | 2026-02-19 | chore: bump version to 0.10.0 | .claude-plugin/plugin.json |
| d9ea8c4 | 2026-02-19 | chore: bump version to 0.9.0 | .claude-plugin/plugin.json |
| f957afb | 2026-02-19 | docs: CHANGELOG.md更新 - v0.8.0 監査修正16件・Tasks統合 | CHANGELOG.md |
| 7b83258 | 2026-02-19 | fix: 監査レポートに基づくプラグイン修正16件 | workflow-manager.sh, codex-wrapper.sh, hooks.json, reinstall-plugin.sh, dev-status.md, marketplace.json, chrome-debugger.md, design/SKILL.md, implementation/SKILL.md, dev-workflow/SKILL.md, using-workflow/SKILL.md, docs/audits/2026-02-19.md |
| 0b22e1d | 2026-02-19 | docs(context): コンテキストドキュメント更新 - テスト-11/12追加 | docs/context/CONTEXT.md |
| 114999c | 2026-02-19 | test: エッジケーステストとフックスクリプトテストを追加 | tests/test-workflow-approval.sh, tests/test-hook-scripts.sh |
| d28a5c1 | 2026-02-19 | feat(plugin-audit): 日本語・マーメイド図付き監査レポート自動生成に対応 | skills/plugin-audit/ |
| 8a94072 | 2026-02-19 | chore: bump version to 0.8.0 | - |
| 485dda5 | 2026-02-19 | docs(context): コンテキストドキュメント更新 - v0.7.0 CHANGELOG追加・バージョン更新 | docs/context/CONTEXT.md |
| 687164f | 2026-02-19 | docs: CHANGELOG.md更新 - v0.7.0 get-dirコマンド追加・パス修正・audit図対応 | CHANGELOG.md |
| e2f8b96 | 2026-02-19 | chore: bump version to 0.7.0 | - |
| 828d160 | 2026-02-19 | docs(context): コンテキストドキュメント更新 - plugin-audit マーメイド図対応 | docs/context/CONTEXT.md |
| 031b754 | 2026-02-19 | feat(skills): plugin-audit のレポートをマーメイド図付きmdファイル出力に変更 | skills/plugin-audit/SKILL.md |
| 0ae3b85 | 2026-02-19 | fix(skills): ハードコードパスをworkflow-manager.sh経由に修正 | skills/dev-workflow, skills/using-workflow, skills/design, skills/failure-memory, skills/implementation |
| 9b47b1e | 2026-02-19 | feat(scripts): workflow-manager.sh に get-dir コマンドを追加 | scripts/workflow-manager.sh |
| 3c780cf | 2026-02-19 | fix(codex-wrapper): macOS互換のtimeout実装に置換 | scripts/codex-wrapper.sh |
| c9c23cf | 2026-02-19 | chore: bump version to 0.6.0 | - |
| 7502d19 | 2026-02-19 | feat: plugin-auditスキル追加 + Phase表示バグ修正 | skills/, scripts/ |
| 565b417 | 2026-02-19 | docs: CHANGELOG.md更新 - plugin-audit追加、workflow-manager修正 | CHANGELOG.md |
| 33435b9 | 2026-02-19 | feat(plugin-audit): スコアリング基準定義を追加 | skills/plugin-audit/references/scoring-rubric.md |
| 12f6927 | 2026-02-19 | feat(plugin-audit): 仕様準拠チェックルール定義を追加 | skills/plugin-audit/references/compliance-rules.md |
| c223d10 | 2026-02-19 | feat(commands): plugin-auditコマンド定義を追加 | commands/plugin-audit.md |
| a3f0c07 | 2026-02-19 | feat(skill): plugin-audit SKILL.md 作成 | skills/plugin-audit/SKILL.md, tests/test-plugin-audit-skill.sh |
| 81239ac | 2026-02-19 | fix(workflow-manager): WORKFLOW_DIRをget_workflow_dir()で解決するよう修正 | scripts/workflow-manager.sh, tests/test-workflow-approval.sh |
| 8b2056c | 2026-02-19 | fix(hooks): バージョンバンプ時にinstalled_plugins.jsonも自動同期 | hooks/check-docs.sh, installed_plugins.json |
| 7eed319 | 2026-02-19 | chore: bump version to 0.5.0 | - |
| e0d8ec5 | 2026-02-19 | docs(context): コンテキストドキュメント更新 - Phase/Sliceバナー表示必須化 | docs/context/ |
| ada8f97 | 2026-02-19 | feat(skills): Phase/Sliceバナー表示の必須化 | skills/, hooks/, commands/ |
| f9e4afc | 2026-02-19 | chore: bump version to 0.4.1 | - |
| e80785b | 2026-02-19 | docs(context): コンテキストドキュメント更新 | docs/context/ |
| 5cc2e3e | 2026-02-19 | fix(hooks): CHANGELOGチェックをorigin/mainベースに修正 | hooks/check-docs.sh |
| 85379a6 | 2026-02-19 | feat(hooks): git push時にconventional commitsからバージョン自動更新 | hooks/check-docs.sh |
| b995e9b | 2026-02-19 | fix(hooks): installPathをソース直接参照に変更しSessionEndフック廃止 | hooks/, installed_plugins.json |
| 6f5041f | 2026-02-19 | fix(hooks): 公式フック仕様への準拠を強化 | hooks/ |
| b0fa753 | 2026-02-19 | feat(hooks): フック再発防止策を実装 | hooks/, scripts/ |
| 6664a11 | 2026-02-19 | fix(hooks): reinstall-plugin.shの自己参照シンボリックリンクを修正 | hooks/ |
| e2410ab | 2026-02-19 | docs(context): コンテキストドキュメント更新 | docs/context/ |
| bb6e8cd | 2026-02-19 | feat(chrome-debug): サーバー管理ポリシーを強化 | skills/chrome-debug/SKILL.md |
| 6bc0265 | 2026-02-19 | feat(skills): Chrome操作をchrome-debuggerエージェントに委任 | skills/ |
| cbd0d79 | 2026-02-19 | feat(hooks): ワークフローディレクトリをworktreeスコープ化 | hooks/ |
| 3e9b10c | 2026-02-19 | feat(agents): Chrome Debuggerエージェント定義を追加 | agents/ |
| 9194228 | 2026-02-19 | fix(codex-wrapper): parse_optionsの引数クォーティングを修正 | scripts/codex-wrapper.sh |
| 7ec80e5 | 2026-02-19 | fix(hooks): QAレビュー推奨修正を適用 | hooks/ |
| a33174a | 2026-02-19 | fix(hooks): hooks.jsonとcheck-approval.shをClaude Code公式フック仕様に準拠 | hooks/ |
| 4ac4e6a | 2026-02-19 | fix(hooks): Claude Code公式フック仕様に準拠 | hooks/ |
| 538a6be | 2026-02-19 | feat(investigation): Phase 2にChrome挙動確認（オプショナル）を追加 | skills/ |
| 7505b65 | 2026-02-19 | feat(hooks): セッション終了時にプラグインを自動再インストールするStopフックを追加 | hooks/ |
| 4af8cef | 2026-02-19 | feat(context): コミット毎のコンテキストドキュメント自動生成機構を追加 | hooks/ |
| 0fe5675 | - | feat(workflow): Phase 6 Chromeデバッグを追加し9Phase体制に拡張 | skills/ |
| c31d717 | - | docs(changelog): v0.2.0とv0.3.0の変更履歴を追加 | CHANGELOG.md |
| f289b42 | - | chore: バージョン0.4.0にアップデート | - |

## 重要な決定事項

### ワークフロー保存先をリポジトリの .git/fractal-workflow/ に変更（2026-02-20）
- **背景**: ユーザーから「ワークフローを作業リポジトリで完結してほしい」という要求があった
- **旧設計**: `~/.claude/fractal-workflow/{md5hash}/` — ホームディレクトリのグローバルな場所に保存していたため、リポジトリと紐付けが弱かった
- **新設計**: `{repo}/.git/fractal-workflow/` — リポジトリの .git ディレクトリ内に保存することで、リポジトリと1対1で管理
- **ワークツリー対応**: ユーザーから「ワークツリーを作ったら同期されないのでは？」という指摘を受け、`git rev-parse --git-common-dir` を使用することでワークツリー間で同じ .git ディレクトリを参照し、共有できる方式に変更
  - 主リポジトリ・ワークツリーのどちらから実行しても同じパスを返す
- **フォールバック**: `workflow-lib.sh` が見つからない場合は `git rev-parse --git-common-dir` を直接呼び出して解決
- **対象ファイル**: `hooks/workflow-lib.sh`（get_workflow_dir 関数の実装変更）、`scripts/workflow-manager.sh`（フォールバック処理の更新）

### 自律判断原則追加（Phase 3設計承認は唯一のユーザー確認ゲート）（2026-02-20）
- **背景**: ワークフロー実行中に各Phase遷移のたびにユーザー確認を挟む実装があり、自律性が損なわれていた
- **決定**: Phase 3（設計・ユーザー承認）のみを唯一のユーザー確認ゲートとし、それ以外の全Phase遷移はエージェントが自律判断で実行する原則を明文化
- **実装**: `skills/dev-workflow/SKILL.md` に「自律判断原則」セクションを追加（27行追加）
- **意図**: ユーザーの介入を最小化し、開発フローを高速化する
- **対象ファイル**: `skills/dev-workflow/SKILL.md`

### Chrome調査をAskUserQuestion廃止・自律判断化（2026-02-20）
- **背景**: Phase 2のChrome調査において、調査の要否を毎回 `AskUserQuestion` でユーザーに確認する実装になっていた
- **決定**: Chrome調査の要否はエージェントが自律判断する。ユーザーへの確認（`AskUserQuestion`）を廃止し、タスク内容・ログ・エラーメッセージからChrome調査の必要性をエージェントが判断する
- **判断基準**: UIバグ・レイアウト崩れ・ブラウザ固有エラー等が疑われる場合はChrome調査を実施
- **実装**: `skills/questioning/SKILL.md` の Phase 2 Chrome調査セクションを更新（28行変更）
- **対象ファイル**: `skills/questioning/SKILL.md`

### Chrome deferred toolsロード必須化（2026-02-20）
- **問題**: `mcp__claude-in-chrome__*` は deferred tools のため、宣言されていても使用前に ToolSearch でロードしないとツールが見つからないエラーが発生していた
- **修正**: `agents/chrome-debugger.md` の観察手順・検証手順の両方に「Step 0: deferred tools のロード（必須）」を追加
  - ToolSearch("mcp__claude-in-chrome") を実行してChromeツールをロード
  - ツールが返ってきたことを確認してから次Stepへ進む
- **同期対象**: `skills/chrome-debug/SKILL.md` の chrome-debugger サブエージェント起動プロンプトにも同様の Step 1（deferred tools ロード）を追加
- **対象ファイル**: `agents/chrome-debugger.md`（14行追加）、`skills/chrome-debug/SKILL.md`（5行追加）

### UIタスクリスト自動作成（Phase 1開始時）（2026-02-20）
- **目的**: dev-workflow スキルでワークフロー開始時にClaude Code Tasks UIパネルを自動表示し、全9Phaseの進捗を可視化する
- **実装**: `skills/dev-workflow/SKILL.md` の「UIタスクリスト初期化（Phase 1開始時のみ）」セクションを新設
  - Phase 1開始時に TaskCreate で全9Phaseのタスクを一括登録
  - 各Phase開始時に TaskUpdate で該当タスクを `in_progress` に更新
  - 各Phase完了時に TaskUpdate で `completed` に更新
- **登録タスク**: Phase 1〜9の全Phase（質問・要件定義/調査/契約設計/Codexレビュー/実装/Chrome検証/コードレビュー/検証/運用設計）
- **対象ファイル**: `skills/dev-workflow/SKILL.md`（26行追加）

### Phase 4/7: workflow-manager.sh approve の実行必須化（2026-02-20）
- **問題**: Phase 4・Phase 7のCodexレビュー完了後に `workflow-manager.sh approve` が実行されず、ワークフロー状態が更新されないままPhase遷移するケースがあった
- **修正**: 以下の箇所に「レビュー完了後（APPROVED/NEEDS_CHANGES問わず）必ず実行」として approve コマンドの実行指示を追加
  - Phase 3→4遷移ルールの末尾（Phase 4完了後の approve + set-phase 5）
  - Phase 6→7遷移ルールの末尾（Phase 7完了後の approve + set-phase 8）
  - codex-delegate サブエージェントプロンプト内（Phase 4・7それぞれ）
  - Red Flags チェックリストに「Phase 4, 7: レビュー完了後に approve を実行したか」を追加
- **実行コマンドパターン**:
  ```bash
  bash ~/.claude/plugins/local/fractal-dev-workflow/scripts/workflow-manager.sh approve {workflow-id} {phase} codex
  bash ~/.claude/plugins/local/fractal-dev-workflow/scripts/workflow-manager.sh set-phase {workflow-id} {next-phase}
  ```
- **対象ファイル**: `skills/dev-workflow/SKILL.md`（17行追加）

### check-docs.shのプラグインリポジトリ内限定化（2026-02-20）
- **問題**: check-docs.shフックはプラグイン自身のリポジトリ専用だが、他プロジェクトのワークツリーでBashツールが実行される際にも発動し、ドキュメントチェックやバージョンバンプが誤って実行されていた
- **修正**: スクリプト冒頭でREPO_ROOT（`git rev-parse --show-toplevel`）とPLUGIN_ROOT（スクリプトの親ディレクトリ）を比較し、一致しない場合は即 `exit 0` でスキップ
- **副作用**: バージョン自動更新ロジックの外側にあった `if [[ "$REPO_ROOT" == "$PLUGIN_ROOT" ]]; then` のネストが不要になったため、インデントを1段階削除してコードを整理（65行挿入・63行削除）
- **対象ファイル**: `hooks/check-docs.sh`（128行変更）

### コミットメッセージ内の「git push」によるgrep誤検出バグ（2026-02-20）
- **発見**: check-docs.shがコミットメッセージを含むgitログをgrepでコマンド判定する際、コミットメッセージ本文に「git push」という文字列が含まれていると誤検出が起きる
- **原因**: `grep -q "git push"` などのパターンが、コマンド引数（コミットメッセージ等）の内容もマッチする
- **対策方針**: grepでコマンド判定する場合はコマンド部分のみを抽出してから比較するか、入力をコマンドフィールドに限定して検索する

### バージョンバンプ時のinstallPathと キャッシュシンボリックリンク同期（2026-02-20）
- **問題**: バージョンバンプ時に installed_plugins.json の version フィールドのみ更新していたが、installPath のシンボリックリンク生成が並行して実行される場合に整合性が崩れる可能性があった
- **修正**: check-docs.sh のバージョン更新処理に以下の処理を追加
  1. 更新したバージョンを読み取り
  2. installPath の対応先シンボリックリンク（`~/.claude/plugins/local/fractal-dev-workflow`）を再構築
  3. installed_plugins.json の installPath フィールドを確認し、存在しない場合は作成
- **対象ファイル**: `hooks/check-docs.sh`（check-version-and-sync セクション、15行追加）
- **副作用**: 複数バージョンの並行管理時にシンボリックリンクが最新バージョンを指すことが保証される

### スクリプト参照を絶対パスに統一（2026-02-20）
- **問題**: worktreeや別ディレクトリから作業する際、スキルファイル内の相対パス（`scripts/workflow-manager.sh`等）でスクリプトが見つからないエラーが発生していた
- **修正**: 全スキルファイルのスクリプト参照を、シンボリックリンク経由の絶対パス（`~/.claude/plugins/local/fractal-dev-workflow/scripts/`）に統一
- **対象ファイル**: 10ファイル（33行変更）
  - `skills/codex-review/SKILL.md`
  - `skills/design/SKILL.md`
  - `skills/dev-workflow/SKILL.md`
  - `skills/failure-memory/SKILL.md`
  - `skills/implementation/SKILL.md`
  - `skills/investigation/SKILL.md`
  - `skills/planning/SKILL.md`
  - `skills/plugin-reinstall/SKILL.md`
  - `skills/post-merge-execute/SKILL.md`
  - `skills/using-workflow/SKILL.md`
- **参照パターン**: `bash ~/.claude/plugins/local/fractal-dev-workflow/scripts/workflow-manager.sh <command>`

### chrome-debuggerエージェントへのChrome MCPツール追加（2026-02-19）
- **問題**: `agents/chrome-debugger.md` のtools定義にChrome MCPツール（`mcp__claude-in-chrome__*`）が未定義だったため、chrome-debuggerエージェントがブラウザ操作ツールを利用できなかった
- **修正**: tools定義に以下13個のMCPツールを追加
  - `mcp__claude-in-chrome__computer`
  - `mcp__claude-in-chrome__find`
  - `mcp__claude-in-chrome__form_input`
  - `mcp__claude-in-chrome__get_page_text`
  - `mcp__claude-in-chrome__gif_creator`
  - `mcp__claude-in-chrome__javascript_tool`
  - `mcp__claude-in-chrome__navigate`
  - `mcp__claude-in-chrome__read_console_messages`
  - `mcp__claude-in-chrome__read_network_requests`
  - `mcp__claude-in-chrome__read_page`
  - `mcp__claude-in-chrome__resize_window`
  - `mcp__claude-in-chrome__tabs_context_mcp`
  - `mcp__claude-in-chrome__tabs_create_mcp`
- **対象ファイル**: `agents/chrome-debugger.md`（13行追加）

### workflow-manager.sh Tasks連携コマンド追加（2026-02-19）
- **目的**: Claude Code Tasks APIとワークフロー状態を連携させ、タスク管理を一元化する
- **追加コマンド**:
  - `tasks`: 現在のワークフローのタスク一覧を表示
  - `add-task <title> [description]`: 新規タスクを追加（TaskCreate相当）
  - `update-task <id> <status>`: タスクステータスを更新（TaskUpdate相当）
- **ID生成**: RANDOM方式から連番方式（既存最大ID+1）に変更し、重複回避を強化
- **対象ファイル**: `scripts/workflow-manager.sh`（108行追加・35行削除）

### plugin-audit スキル改修（2026-02-19）
- **目的**: 監査レポートを日本語・マーメイド図付きの md ファイルとして出力
- **実装**: `skills/plugin-audit/SKILL.md` の出力仕様を更新
  - 3種類のマーメイド図をテンプレート化（Pie Chart、Gauge Chart、Flowchart）
  - 出力は日本語で統一
- **保存先**: `docs/audits/YYYY-MM-DD.md` に日付管理形式で保存
- **対象ファイル**: `skills/plugin-audit/SKILL.md`、`docs/audits/2026-02-19.md`

### 監査レポート16件修正（2026-02-19）
- **セキュリティ修正**:
  - [C-1] `workflow-manager.sh`: `create_workflow()` の JSON インジェクション修正（`jq -n --arg` 使用）
  - [I-1] `codex-wrapper.sh`: `run_with_retry()` の終了コード修正
- **整合性修正**:
  - [I-2] `hooks.json`: SessionEnd フック登録（reinstall-plugin.sh）
  - [F-1] `dev-status.md`: フェーズ番号修正（4 and 6 → 4 and 7）
  - [F-2] `using-workflow/SKILL.md`: スキル名・Phase 名を仕様に整合
  - [F-3] `marketplace.json`: バージョン 0.8.0・9 フェーズ説明に更新
  - [M-1] `reinstall-plugin.sh`: ハードコードパスをスクリプト位置解決に変更
- **推奨修正**:
  - `chrome-debugger.md`: tools フロントマター追加
  - `workflow-manager.sh`: RANDOM ID 生成を連番方式に改善
- **Tasks 統合**:
  - `design/SKILL.md`: TaskCreate 具体例追加、TaskUpdate 誤記修正
  - `implementation/SKILL.md`: Strategy A/B に TaskCreate/TaskUpdate 記述追加
  - `dev-workflow/SKILL.md`: Phase 3/5 完了条件に Tasks 要件追加

### サブエージェントのレポート出力ファイル保存（2026-02-19）
- **問題**: サブエージェントがレポートを生成しても、ファイル保存されずに消えていた
- **対策**: スキルに「レポートは `docs/audits/YYYY-MM-DD.md` に保存すること」を明記し、出力要件を強制化

### Phase Banner Protocol（2026-02-19）
- **目的**: 各Phase開始時にバナー表示を必須化し、現在のPhaseを明確にする
- **実装**: `skills/dev-workflow/SKILL.md` に Phase Banner Protocol セクションを新設
- **仕様**: 全9Phase分の名称マッピングを定義（例: Phase 1 = 質問・要件確認）
- **参照追加**: 全8スキルファイル（chrome-debug, codex-review, completion, design, investigation, questioning, verification + implementation）にバナー参照を追加
- **session-init.sh**: セッション再開時にPhase/Slice情報を表示するよう拡張
- **コマンド**: dev-status, dev-resume コマンドにバナー表示指示を追加

### Slice Banner Protocol（2026-02-19）
- **目的**: Phase 5（実装フェーズ）の各Slice開始時にバナー表示を必須化
- **実装**: `skills/implementation/SKILL.md` に Slice Banner Protocol セクションを新設
- **仕様**: 3Slice分の名称マッピングを定義（Slice 1 = バックエンド実装、Slice 2 = フロントエンド実装、Slice 3 = 統合テスト）
- **対象ファイル**: `skills/implementation/SKILL.md`（40行追加）

### wf-*.jsonスキーマ拡張（2026-02-19）
- **目的**: ワークフロー状態ファイルでSlice情報を追跡可能にする
- **追加フィールド**:
  - `currentSlice`: 現在実行中のSlice番号（1-3）
  - `slices`: 各Sliceの状態オブジェクト（completed, inProgress等）
- **対象ファイル**: `skills/dev-workflow/SKILL.md`（スキーマ定義部分）

### CHANGELOGチェックのorigin/mainベース修正（2026-02-19）
- **問題**: `git diff main` はローカルのmainブランチとの比較だったため、リモートへのpush前にローカルmainを更新していない場合に誤検知が発生していた
- **修正**: `git rev-parse --abbrev-ref --symbolic-full-name @{u}` でリモートトラッキングブランチ（origin/main等）を動的に取得し、そのリファレンスに対して差分チェックするよう変更
- **副作用**: リモートトラッキングブランチが存在しない場合はチェックをスキップするように条件分岐を追加
- **対象ファイル**: `hooks/check-docs.sh`（CHANGELOGチェック部分、約91-105行目）

### settings.jsonへのフック直接定義（2026-02-19）
- **背景**: プラグインのPreToolUseフックに既知バグがあり、プラグインフック経由では正常に動作しないケースがある
- **ワークアラウンド**: プロジェクトまたはユーザーの `settings.json` にフックを直接定義することで、プラグインフックのバグを回避
- **対象**: PreToolUseフックを利用する機能全般

### サーバー管理ポリシー強化（2026-02-19）
- **目的**: Chrome Debuggerエージェント統合時のサーバー管理を堅牢化
- **内容**:
  - ポート3100を固定利用
  - worktree起動時のサーバー起動を必須化
  - 完了後のサーバー停止を必須化
  - 並列実行を禁止（単一サーバーインスタンスの原則）
- **対象ファイル**: `skills/chrome-debug/SKILL.md`

### Chrome操作の委任戦略（2026-02-19）
- **背景**: Chrome自動化操作がgeneral-purposeエージェントで複雑化・肥大化していた
- **施策**: 以下の操作をchrome-debuggerエージェントに委任
  - スクリーンショット撮影
  - フォーム入力・クリック
  - ページナビゲーション
  - 検証・確認
- **効果**: スキル管理の簡潔化、役割分離の明確化
- **実装ファイル**: `skills/dev-workflow/SKILL.md` など

### ワークフローディレクトリのworktreeスコープ化（2026-02-19）
- **目的**: 複数worktree間での干渉を防止
- **実装**: `workflow-lib.sh` に `get_workflow_dir()` 関数を追加
- **仕様**: `$HOME/.claude/workflows/<WORKFLOW_NAME>/<WORKTREE_NAME>/` 配下にスコープ
- **対象**: セッション設定、テンプラスト、ログ等

### SKILL.mdのハードコードパスをworkflow-manager.sh経由に修正（2026-02-19）
- **目的**: 複数スキルでハードコードされていた `~/.claude/fractal-workflow/` パスをworktreeスコープ対応に統一
- **修正箇所**:
  - `skills/dev-workflow/SKILL.md`: 4箇所（状態更新説明、チェックリスト、failure-memory連携、Workflow State Managementセクション）
  - `skills/using-workflow/SKILL.md`: State Files の2パス
  - `skills/design/SKILL.md`: jqコマンド内のパスをWFDIR変数経由に変更
  - `skills/failure-memory/SKILL.md`: LocationパスをGET-DIR経由に変更
  - `skills/implementation/SKILL.md`: 状態更新説明をworkflow-manager.sh経由に変更
- **統一パターン**: `$(bash scripts/workflow-manager.sh get-dir)/` をパスプレフィックスに使用

### workflow-manager.sh に get-dir コマンド追加（2026-02-19）
- **目的**: スキルから `bash scripts/workflow-manager.sh get-dir` でworktreeスコープのワークフローディレクトリパスを取得できるようにする
- **実装**: case文に `get-dir) echo "$WORKFLOW_DIR" ;;` を追加、ヘルプにも追記
- **背景**: session-init.sh のフォールバック削除（worktreeスコープ設計維持）と合わせた整合性確保
- **対象ファイル**: `scripts/workflow-manager.sh`（2行追加）

### workflow-manager.sh のWORKFLOW_DIR解決修正（2026-02-19）
- **問題**: `workflow-manager.sh` が `$HOME/.claude/fractal-workflow` を直接参照していたため、`session-init.sh` が参照するmd5ハッシュベースのパスと不一致が発生。Phase情報が表示されないバグの原因だった
- **修正**: `workflow-manager.sh` の冒頭で `hooks/workflow-lib.sh` を source し、`WORKFLOW_DIR` のデフォルト値を `get_workflow_dir()` の結果に変更
- **後方互換性**: `WORKFLOW_DIR` 環境変数が明示的に設定されている場合は引き続きその値を優先（既存テストは環境変数でオーバーライドするため互換性を維持）
- **フォールバック**: `workflow-lib.sh` が見つからない場合は従来パス（`$HOME/.claude/fractal-workflow`）を維持
- **テスト**: Test 9を追加（25/25 passed）

### macOS互換のtimeout実装（2026-02-19）
- **問題**: macOSには `timeout` コマンドが標準搭載されていないため、`codex-wrapper.sh` の `timeout codex ...` 呼び出しが `command not found` エラーになっていた
- **解決**: バックグラウンドプロセス + `kill` による手動タイムアウト実装に置換
  - Codexをバックグラウンド実行し、PIDを保持
  - 指定秒数後に `kill $pid` でプロセスを強制終了
  - `wait $pid` で終了コードを取得
- **効果**: macOS（Homebrew `coreutils` 不要）でもLinuxと同等のタイムアウト動作を実現
- **対象ファイル**: `scripts/codex-wrapper.sh`（24行追加、3行削除）

### parse_options の引数クォーティング問題（2026-02-19）
- **問題**: `echo "${filtered_args[@]}"` を使用していたため、`eval` 実行時に日本語全角括弧等の特殊文字がシェル構文として解釈されエラーになっていた
- **修正**: `printf '%q ' "${filtered_args[@]}"` に変更し、各引数をシェルセーフにクォートするよう対応
- **対象ファイル**: `scripts/codex-wrapper.sh` の `parse_options` 関数（66行目付近）

### plugin-audit レポート出力形式の md + マーメイド図化（2026-02-19）
- **目的**: スコアリング結果の可視化を強化し、ユーザーが監査結果を一目で把握できるようにする
- **実装**: `skills/plugin-audit/SKILL.md` の出力仕様を以下に変更
  - **md ファイル出力**: 監査結果を markdown ファイル形式で構造化出力
  - **マーメイド図挿入**: 以下2種類の図を出力に含める
    - **Pie Chart**: 5カテゴリ（Structure/Compliance/Flow/Token/Security）の配点比率を視覚化
    - **Gauge Chart**: 総合スコア（0-100）の進捗状況を視覚化
  - **出力先**: workflow 状態ファイルの `audit_report` フィールドに md テキストを格納
  - **ユーザー可視化**: ユーザーが md ファイルを Canva/Markdown ビューアで開くと図が自動レンダリング
- **セクション構成**:
  1. タイトル・日時
  2. 総合スコア + Gauge Chart
  3. カテゴリ別得点 + Pie Chart
  4. 詳細判定（Critical/Warn/Pass）
  5. 改善提案

### Claude Code公式フック仕様への準拠（2026-02-19）
- hooks/ 配下の複数スクリプト（session-init.sh, check-docs.sh, check-approval.sh, hooks.json）をClaude Code公式フック仕様に準拠させる一連の修正を実施
- QAレビュー推奨修正も適用済み

### installPathソース直接参照（2026-02-19）
- **問題**: installPathがキャッシュパスだと、キャッシュ破損時にフック全体が無効化される（鶏と卵問題）
- **解決**: `installed_plugins.json`のinstallPathをソースディレクトリ(`/Users/t.asai/code/fractal-dev-workflow`)直接に変更
- **副作用**: SessionEndフック廃止（キャッシュ更新不要）、CLAUDE_PLUGIN_ROOTがソース直接になるため新セッションから有効

### バージョン自動バンプ（2026-02-19）
- git push時にcheck-docs.shがconventional commitsからバンプタイプを判定
- BREAKING CHANGE → major, feat → minor, その他 → patch
- fractal-dev-workflowリポジトリのpush時のみ動作
- 二重バンプ防止: 直近コミットが`chore: bump version`の場合はスキップ

### バージョンバンプ時のinstalled_plugins.json自動同期（2026-02-19）
- **目的**: バージョン変更後、installed_plugins.jsonの`version`フィールドを自動更新
- **実装**: check-docs.shがバージョン更新後、installed_plugins.jsonを読み込み→version更新→同じ内容を書き戻し
- **タイミング**: バージョンバンプ直後（sed実行直後）
- **対象ファイル**: hooks/check-docs.sh（バージョン更新処理の直後）

### 9Phase体制（2026-02-19時点）
- Phase 1: 質問・要件確認
- Phase 2: 調査（Chrome挙動確認をオプショナルで追加）
- Phase 3: 計画作成・ユーザー承認
- Phase 4: Codexレビュー
- Phase 5: 実装（worktree必須）
- Phase 6: Chromeデバッグ
- Phase 7: QAレビュー
- Phase 8: 完了・PR作成
- Phase 9: セッション終了・プラグイン再インストール

### コンテキスト自動保存機構（2026-02-19）
- コミット毎にコンテキストドキュメントを自動生成するStopフックを追加
- 本ファイル（docs/context/CONTEXT.md）がその成果物

## ミスと教訓

| 日付 | 内容 | 教訓 |
|---|---|---|
| 2026-02-20 | check-docs.shが他プロジェクトのワークツリーでも誤作動していた | フック冒頭でREPO_ROOTとPLUGIN_ROOTを比較し、対象外リポジトリでは即exit 0するスコープガードを実装する |
| 2026-02-20 | コミットメッセージ内に「git push」を含むと、check-docs.shのgrepコマンド判定が誤検出する | grepでコマンド判定する際は、コマンド引数（コミットメッセージ等）の内容もマッチする可能性があることを常に考慮し、コマンド部分のみを抽出して比較する |
| 2026-02-19 | サブエージェントのレポート出力がファイル保存されていなかった | スキルに出力ファイルパス（docs/audits/YYYY-MM-DD.md）と保存コマンドを明記し、出力要件を強制化する |
| 2026-02-19 | plugin-audit SKILL.md 日本語化でテストパターン不一致が発生した | スキル仕様変更時はテストの期待値も同時に更新し、日本語対応を徹底する |
| 2026-02-19 | Chrome Debuggerへの委任設計時、サーバー管理ポリシーが不十分だった | サーバー操作を伴う機能は起動・停止・並列実行禁止を事前に明記し、ゲート化する |
| 2026-02-19 | worktreeスコープ化を遅延実装していた | 複数worktree対応の際は実装当初からディレクトリスコープを設計に含める |
| 2026-02-19 | `echo` で配列を渡した後 `eval` すると全角文字がシェル構文エラーになる | `eval` と組み合わせる場合は必ず `printf '%q '` を使用し、各引数をクォートする |
| 2026-02-19 | Claude Code公式フック仕様との非準拠が複数箇所で発生 | フック実装時は公式仕様を事前確認し、一括で準拠させる |
| 2026-02-19 | reinstall-plugin.shがCLAUDE_PLUGIN_ROOTから自己参照シンボリックリンクを作成 | CLAUDE_PLUGIN_ROOTはキャッシュパスを返すためソース解決に使用禁止 |
| 2026-02-19 | キャッシュ破損時にフック自体が読み込めなくなる鶏と卵問題 | installPathはソース直接参照にすべき |

## ユーザーとの対話要約

| 日付 | 重要な指示・決定 |
|---|---|
| 2026-02-20 | ワークフロー保存先を `~/.claude/fractal-workflow/{hash}/` から `{repo}/.git/fractal-workflow/` に変更。ワークツリー間共有のため `git rev-parse --git-common-dir` を使用する方式に変更 |
| 2026-02-20 | Chrome deferred toolsロードの必須化と、dev-workflowスキルへのUIタスクリスト自動作成機能の追加を実施。Phase 4/7のCodexレビュー後にworkflow-manager.sh approveを必須実行するよう明記 |
| 2026-02-20 | check-docs.shフックをプラグインリポジトリ内のみに限定する修正を指示。コミットメッセージ内の「git push」がフックのgrep誤検出を起こすバグも発見された |
| 2026-02-20 | worktreeや別ディレクトリからスクリプトが見つからないエラーの報告を受け、全スキルファイルのスクリプト参照を相対パスからシンボリックリンク経由の絶対パス（`~/.claude/plugins/local/fractal-dev-workflow/scripts/`）に統一するよう指示 |
| 2026-02-19 | 「日本語で記述が必須」→ plugin-audit の全出力物（SKILL.md・レポート）を日本語化 |
| 2026-02-19 | 「マーメイド図を用いたmdファイル生成が必要」→ Pie Chart・Gauge Chart・Flowchart の3種類のマーメイド図をテンプレート化し、docs/audits/YYYY-MM-DD.md に日付管理形式で保存 |
| 2026-02-19 | 「workflow-manager.shをtasks統合」→ tasks/add-task/update-task サブコマンドを追加し、RANDOM ID 生成を連番方式に変更 |
| 2026-02-19 | 「プラグインのスキルで正しくtasksが使用できるようにすること」→ design/implementation/dev-workflow 各スキルに TaskCreate/TaskUpdate 指示を追加 |
| 2026-02-19 | [テスト-11] test-workflow-approval.sh にエッジケーステスト4件追加（JSONインジェクション回帰・連番ID重複回避・不正IDフォーマット拒否・Tasks連携コマンド）。[テスト-12] test-hook-scripts.sh を新規作成（フックスクリプトのユニットテスト5件）。session-init.sh は WORKFLOW_DIR 環境変数を無視して get_workflow_dir() で決定することを確認し、テスト仕様を実態に合わせて調整 |
| 2026-02-19 | plugin-audit レポート出力をマーメイド図付き md ファイル形式に変更。Pie Chart（カテゴリ配点比率）と Gauge Chart（総合スコア）を含む視覚化対応 |
| 2026-02-19 | SKILL.mdファイルのハードコードパス（~/.claude/fractal-workflow/）をworkflow-manager.sh経由（bash scripts/workflow-manager.sh get-dir）に修正するよう指示 |
| 2026-02-19 | session-init.sh のフォールバック削除（既にコミット済みで不要）、workflow-manager.sh に get-dir コマンドを追加してworktreeスコープのディレクトリパス取得を可能にするよう指示 |
| 2026-02-19 | Slice 5: scoring-rubric.md 作成。5カテゴリ（Structure/Compliance/Flow/Token/Security）各20点合計100点のスコアリング基準を詳細定義。PASS/WARN/FAILの閾値、各サブ項目の採点条件、SeverityマッピングをSKILL.mdから参照される形式で整備 |
| 2026-02-19 | Slice 4: compliance-rules.md 作成。Claude Code公式仕様に基づく6カテゴリ27ルールを定義し、Critical不合格時の自動FAIL判定ポリシーと証拠記録形式を規定 |
| 2026-02-19 | Slice 3: plugin-audit コマンド定義追加。/plugin-auditスラッシュコマンドを定義し、fractal-dev-workflow:plugin-auditスキルをTaskツールで起動する仕様で実装 |
| 2026-02-19 | Slice 2: plugin-audit SKILL.md 作成。5カテゴリ（Structure/Compliance/Flow/Token/Security）100点評価スキルをTDDで実装（31/31テストPASS） |
| 2026-02-19 | Slice 1: Phase表示バグ修正。workflow-manager.shがget_workflow_dir()と異なるパスを参照していた不一致を解消 |
| 2026-02-19 | Chrome Debuggerエージェント統合およびサーバー管理ポリシー強化を完了 |
| 2026-02-19 | コンテキストドキュメント自動生成機構の追加を指示。コミット毎にdocs/context/CONTEXT.mdを更新する仕組みを実装 |
| 2026-02-19 | codex-wrapper.shのparse_options関数で `echo` を `printf '%q '` に変更し、日本語全角括弧等の特殊文字対応を指示 |
| 2026-02-19 | ワークフローをworktree毎にスコープ化する要件（リポジトリ毎ではなくworktree毎） |
| 2026-02-19 | installPathをソース直接参照に変更し、キャッシュ依存を排除 |
| 2026-02-19 | バージョン自動バンプ（push時にconventional commitsから判定）を実装 |
