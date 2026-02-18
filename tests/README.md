# テスト実行手順

## 背景

このプロジェクトはフックシステムにより、通常のBash実行が制限されています。テストを実行する際は、以下の手順に従ってください。

## テスト実行方法

### オプション1: フック無効化（一時的）

```bash
# フックを一時的に無効化
mv .claude-plugin/hooks.json .claude-plugin/hooks.json.bak

# テスト実行
./tests/test-workflow-approval.sh

# フックを復元
mv .claude-plugin/hooks.json.bak .claude-plugin/hooks.json
```

### オプション2: 手動テスト

```bash
# テスト用ワークフローディレクトリを設定
export WORKFLOW_DIR="/tmp/test-workflow-$$"
mkdir -p "$WORKFLOW_DIR"

# 1. 9フェーズワークフローの作成
wf_id=$(./scripts/workflow-manager.sh create "Test workflow")
echo "Created workflow: $wf_id"

# 2. 状態確認
./scripts/workflow-manager.sh get "$wf_id" | jq '.phases | length'
# Expected: 9

# 3. Codex承認のテスト
source ./scripts/workflow-manager.sh
approve "$wf_id" "4" "codex"
./scripts/workflow-manager.sh get "$wf_id" | jq '.phases["4"].codexApprovedAt'
# Expected: タイムスタンプが表示される

# 4. User承認のテスト
approve "$wf_id" "4" "user"
./scripts/workflow-manager.sh get "$wf_id" | jq '.phases["4"]'
# Expected: userApprovedAtとstatus: "completed"が表示される

# クリーンアップ
rm -rf "$WORKFLOW_DIR"
```

## テストケース

### Test 1: 9フェーズワークフロー作成

- フェーズ数が9であること
- 各フェーズのstatusが`pending`であること

### Test 2: Codex承認

- `approve <wf_id> <phase> "codex"` で `codexApprovedAt` が記録されること
- `userApprovedAt` は未設定であること
- statusは変更されないこと

### Test 3: User承認

- `approve <wf_id> <phase>` (デフォルト) で `userApprovedAt` が記録されること
- statusが `completed` に変更されること

### Test 4: 2段階承認

- Codex承認後にUser承認が可能
- 両方のタイムスタンプが記録されること

## check-approval.sh のテスト

### Phase 4 承認チェック

```bash
# テストワークフローを作成
wf_id=$(./scripts/workflow-manager.sh create "Test approval check")

# Phase 4に移動
./scripts/workflow-manager.sh set-phase "$wf_id" 4

# この状態でWrite/Editを試みる → ブロックされるはず
# Expected error: "Phase 4 (計画レビュー) のCodex承認とユーザー承認が必要です"

# Codex承認のみ
source ./scripts/workflow-manager.sh
approve "$wf_id" "4" "codex"

# まだブロックされる
# Expected error: "Phase 4 (計画レビュー) のCodex承認とユーザー承認が必要です"
# Codex: ✓, User: ✗

# User承認
approve "$wf_id" "4" "user"

# Phase 5に移動
./scripts/workflow-manager.sh set-phase "$wf_id" 5

# この状態でWrite/Editが可能になる
```

### Phase 7 承認チェック

```bash
# Phase 8に移動
./scripts/workflow-manager.sh set-phase "$wf_id" 8

# この状態でWrite/Editを試みる → ブロックされるはず
# Expected error: "Phase 7 (コードレビュー) のCodex承認とユーザー承認が必要です"

# Codex承認
approve "$wf_id" "7" "codex"

# User承認
approve "$wf_id" "7" "user"

# この状態でWrite/Editが可能になる
```

## CI/CDでの実行

将来的にCI/CDパイプラインを構築する場合は、以下のようにフックを無効化した環境でテストを実行します。

```yaml
# .github/workflows/test.yml (例)
- name: Run tests
  run: |
    # フック無効化環境でテスト実行
    CLAUDE_DISABLE_HOOKS=1 ./tests/test-workflow-approval.sh
```
