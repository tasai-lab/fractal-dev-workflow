# コンテキストドキュメント

最終更新: 2026-02-19（c223d10）

## 現在の状態

- **Phase**: 開発安定化フェーズ
- **進行中タスク**: Slice 3 完了（plugin-audit コマンド定義追加）
- **バージョン**: 0.5.1（push時にconventional commitsで自動バンプ）

## 実装経緯テーブル

| コミットハッシュ | 日付 | 内容 | 影響範囲 |
|---|---|---|---|
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

### workflow-manager.sh のWORKFLOW_DIR解決修正（2026-02-19）
- **問題**: `workflow-manager.sh` が `$HOME/.claude/fractal-workflow` を直接参照していたため、`session-init.sh` が参照するmd5ハッシュベースのパスと不一致が発生。Phase情報が表示されないバグの原因だった
- **修正**: `workflow-manager.sh` の冒頭で `hooks/workflow-lib.sh` を source し、`WORKFLOW_DIR` のデフォルト値を `get_workflow_dir()` の結果に変更
- **後方互換性**: `WORKFLOW_DIR` 環境変数が明示的に設定されている場合は引き続きその値を優先（既存テストは環境変数でオーバーライドするため互換性を維持）
- **フォールバック**: `workflow-lib.sh` が見つからない場合は従来パス（`$HOME/.claude/fractal-workflow`）を維持
- **テスト**: Test 9を追加（25/25 passed）

### parse_options の引数クォーティング問題（2026-02-19）
- **問題**: `echo "${filtered_args[@]}"` を使用していたため、`eval` 実行時に日本語全角括弧等の特殊文字がシェル構文として解釈されエラーになっていた
- **修正**: `printf '%q ' "${filtered_args[@]}"` に変更し、各引数をシェルセーフにクォートするよう対応
- **対象ファイル**: `scripts/codex-wrapper.sh` の `parse_options` 関数（66行目付近）

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
| 2026-02-19 | Chrome Debuggerへの委任設計時、サーバー管理ポリシーが不十分だった | サーバー操作を伴う機能は起動・停止・並列実行禁止を事前に明記し、ゲート化する |
| 2026-02-19 | worktreeスコープ化を遅延実装していた | 複数worktree対応の際は実装当初からディレクトリスコープを設計に含める |
| 2026-02-19 | `echo` で配列を渡した後 `eval` すると全角文字がシェル構文エラーになる | `eval` と組み合わせる場合は必ず `printf '%q '` を使用し、各引数をクォートする |
| 2026-02-19 | Claude Code公式フック仕様との非準拠が複数箇所で発生 | フック実装時は公式仕様を事前確認し、一括で準拠させる |
| 2026-02-19 | reinstall-plugin.shがCLAUDE_PLUGIN_ROOTから自己参照シンボリックリンクを作成 | CLAUDE_PLUGIN_ROOTはキャッシュパスを返すためソース解決に使用禁止 |
| 2026-02-19 | キャッシュ破損時にフック自体が読み込めなくなる鶏と卵問題 | installPathはソース直接参照にすべき |

## ユーザーとの対話要約

| 日付 | 重要な指示・決定 |
|---|---|
| 2026-02-19 | Slice 3: plugin-audit コマンド定義追加。/plugin-auditスラッシュコマンドを定義し、fractal-dev-workflow:plugin-auditスキルをTaskツールで起動する仕様で実装 |
| 2026-02-19 | Slice 2: plugin-audit SKILL.md 作成。5カテゴリ（Structure/Compliance/Flow/Token/Security）100点評価スキルをTDDで実装（31/31テストPASS） |
| 2026-02-19 | Slice 1: Phase表示バグ修正。workflow-manager.shがget_workflow_dir()と異なるパスを参照していた不一致を解消 |
| 2026-02-19 | Chrome Debuggerエージェント統合およびサーバー管理ポリシー強化を完了 |
| 2026-02-19 | コンテキストドキュメント自動生成機構の追加を指示。コミット毎にdocs/context/CONTEXT.mdを更新する仕組みを実装 |
| 2026-02-19 | codex-wrapper.shのparse_options関数で `echo` を `printf '%q '` に変更し、日本語全角括弧等の特殊文字対応を指示 |
| 2026-02-19 | ワークフローをworktree毎にスコープ化する要件（リポジトリ毎ではなくworktree毎） |
| 2026-02-19 | installPathをソース直接参照に変更し、キャッシュ依存を排除 |
| 2026-02-19 | バージョン自動バンプ（push時にconventional commitsから判定）を実装 |
