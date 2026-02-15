---
name: post-merge-tasks
description: PR作成時にマージ後に必要なタスクを収集し、実行可能な形式で記録する。DBマイグレーション、環境変数設定、デプロイ作業等の手順を整理。
---

# Post-Merge Tasks

## Overview

PRマージ後に実行すべきタスク（DBマイグレーション、環境変数設定、デプロイ作業等）を構造化して記録し、実行漏れを防ぐ。

**Core principle:** Record before merge, execute after merge, verify completion.

## The Iron Law

```
NO MERGE WITHOUT POST-MERGE CHECKLIST
```

マージ後にやるべきことが不明確なPRは作成してはならない。

## When to Use

- PR作成時
- マージ後に手作業が必要な変更を含む場合
- DBスキーマ変更がある場合
- 環境変数追加・変更がある場合
- デプロイ設定変更がある場合
- 外部サービス設定変更が必要な場合

## The Process

```dot
digraph post_merge {
    "Start PR creation" -> "Identify post-merge tasks";
    "Identify post-merge tasks" -> "Has tasks?" [shape=diamond];
    "Has tasks?" -> "Create task file" [label="yes"];
    "Create task file" -> "Add PR section";
    "Add PR section" -> "Create PR";
    "Has tasks?" -> "Create PR" [label="no"];
    "Create PR" -> "PR merged";
    "PR merged" -> "Execute tasks";
    "Execute tasks" -> "Mark as completed";
    "Mark as completed" -> "Verify execution";
    "Verify execution" -> "Archive task file";
}
```

## Task Categories

### 1. Database Migrations

データベーススキーマ変更を含む場合に記録。

```markdown
- [ ] DBマイグレーション: `npm run migrate`
  - 対象: users テーブルに email_verified カラム追加
  - 影響: 既存レコードは NULL になるため、デフォルト値設定が必要
```

### 2. Environment Variables

新規環境変数や既存環境変数の変更。

```markdown
- [ ] 環境変数設定: `DATABASE_URL`
  - 値: `postgresql://user:pass@localhost:5432/dbname`
  - 場所: .env, .env.production
  - 影響: データベース接続に必須
```

### 3. Deployment Tasks

デプロイ設定やインフラ変更。

```markdown
- [ ] デプロイ設定更新: `kubectl apply -f k8s/deployment.yaml`
  - 変更: メモリリミット 512MB → 1GB
  - 理由: パフォーマンス改善のため
```

### 4. Configuration Changes

設定ファイルや外部サービスの設定変更。

```markdown
- [ ] Nginx設定更新: `/etc/nginx/sites-available/app.conf`
  - 変更: `/api/v2` エンドポイント追加
  - 再起動: `sudo systemctl reload nginx`
```

### 5. Data Migration

既存データの変換や移行。

```markdown
- [ ] データ移行スクリプト実行: `npm run migrate:data`
  - 内容: 旧形式の user_preferences を新形式に変換
  - 所要時間: 約5分（10,000レコード）
  - バックアップ: 実行前に必ず取得
```

### 6. External Service Setup

外部サービスの設定変更や連携。

```markdown
- [ ] Stripe Webhook URL更新
  - 新URL: `https://api.example.com/webhooks/stripe`
  - 場所: Stripe Dashboard > Developers > Webhooks
  - イベント: `checkout.session.completed`, `payment_intent.succeeded`
```

### 7. Custom Tasks

上記に当てはまらないカスタムタスク。

```markdown
- [ ] キャッシュクリア: `redis-cli FLUSHALL`
  - 理由: API レスポンス形式変更のため
  - 影響: 一時的にレスポンス速度低下の可能性
```

## Task File Template

### File Location

```
docs/post-merge-tasks/{branch-name}.md
```

**例:**
```
docs/post-merge-tasks/feature-user-authentication.md
docs/post-merge-tasks/fix-payment-bug.md
docs/post-merge-tasks/refactor-api-structure.md
```

### File Content

```markdown
# Post-Merge Tasks: {branch-name}

## Status: pending

## Merge Info
- Branch: {branch-name}
- Base: {base-branch}
- Created: {YYYY-MM-DD}
- PR: #{pr-number}
- Merged: {YYYY-MM-DD} (after merge)
- Completed: {YYYY-MM-DD} (after all tasks)

## Tasks

### Database Migrations
- [ ] [タスク説明]: `コマンド`
  - 詳細: [追加情報]
  - 影響: [影響範囲]

### Environment Variables
- [ ] [変数名]: `値`
  - 場所: [ファイルパス]
  - 影響: [影響範囲]

### Deployment
- [ ] [タスク説明]: `コマンド`
  - 理由: [なぜ必要か]
  - 検証: [どう確認するか]

### Configuration
- [ ] [設定名]: `設定値`
  - ファイル: [パス]
  - 再起動: [必要な操作]

### Data Migration
- [ ] [タスク説明]: `コマンド`
  - 所要時間: [見積もり]
  - バックアップ: [必要な手順]

### External Services
- [ ] [サービス名]: [設定内容]
  - アクセス: [どこで設定するか]
  - 検証: [動作確認方法]

### Custom
- [ ] [タスク説明]: `コマンド`
  - 理由: [なぜ必要か]
  - 注意: [特記事項]

## Execution Notes

### Pre-execution Checklist
- [ ] バックアップ取得済み
- [ ] 依存タスクの完了確認
- [ ] 実行環境の確認
- [ ] ロールバック手順の準備

### Execution Order
1. [タスク1] → [タスク2] → [タスク3]
2. 並列実行可能: [タスク4], [タスク5]

### Rollback Plan
- タスク1失敗時: [ロールバック手順]
- タスク2失敗時: [ロールバック手順]

### Verification
- [ ] [検証項目1]: `テストコマンド`
- [ ] [検証項目2]: `確認方法`

## Notes
<!-- 実行時の追加メモ、発生した問題、解決方法等 -->
```

## PR Description Section Template

PR作成時に以下のセクションをPR説明に追加する。

```markdown
## Post-Merge Tasks

マージ後に以下のタスクを実行してください:

### Database Migrations
- [ ] DBマイグレーション: `npm run migrate`

### Environment Variables
- [ ] `DATABASE_URL` を設定: `postgresql://...`
- [ ] `JWT_SECRET` を設定（新規）

### Deployment
- [ ] メモリリミット更新: `kubectl apply -f k8s/deployment.yaml`

### Configuration
- [ ] Nginx設定更新: `/etc/nginx/sites-available/app.conf`

---

> 詳細: [docs/post-merge-tasks/{branch-name}.md](./docs/post-merge-tasks/{branch-name}.md)
> `/post-merge` コマンドで実行可能
```

**ミニマル版（タスクが少ない場合）:**

```markdown
## Post-Merge Tasks

- [ ] DBマイグレーション: `npm run migrate`
- [ ] 環境変数 `NEW_API_KEY` を設定

> `/post-merge` コマンドで実行可能
```

## Workflow Integration

### Step 1: PR作成前にタスク収集

```bash
# タスクファイル作成
docs/post-merge-tasks/{branch-name}.md

# 内容を記述（テンプレート使用）
```

### Step 2: PRにセクション追加

```bash
# PR作成時にセクションを含める
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
[変更内容]

## Post-Merge Tasks
[タスクリスト]

> 詳細: docs/post-merge-tasks/{branch-name}.md
EOF
)"
```

### Step 3: マージ後にタスク実行

```bash
# タスクファイルを開く
cat docs/post-merge-tasks/{branch-name}.md

# タスクを順番に実行
npm run migrate
# ...

# 完了したらチェック
# - [x] DBマイグレーション: `npm run migrate`
```

### Step 4: 完了確認と記録

```bash
# ステータス更新
## Status: pending → completed

# 完了日時記録
- Completed: 2025-02-15

# アーカイブ（オプション）
mkdir -p docs/post-merge-tasks/archive
mv docs/post-merge-tasks/{branch-name}.md docs/post-merge-tasks/archive/
```

## Command Integration

### `/post-merge` Command (Future)

将来的に実装予定のコマンド。

```bash
# タスクファイル作成
/post-merge create

# タスク追加
/post-merge add "DBマイグレーション: npm run migrate"

# タスク一覧表示
/post-merge list

# タスク実行
/post-merge exec migration

# 完了マーク
/post-merge done migration

# ステータス確認
/post-merge status
```

## Best Practices

### 1. Be Specific

```
❌ Bad:
- [ ] データベース更新

✓ Good:
- [ ] DBマイグレーション: `npx prisma migrate deploy`
  - 対象: users テーブルに email_verified カラム追加
  - 影響: 既存レコードはデフォルト false
  - 所要時間: 約30秒
```

### 2. Include Verification

```
❌ Bad:
- [ ] 環境変数設定

✓ Good:
- [ ] 環境変数設定: `DATABASE_URL`
  - 値: `postgresql://user:pass@host:5432/db`
  - 場所: .env.production
  - 検証: `npm run db:test-connection`
```

### 3. Document Dependencies

```
✓ Good:
## Execution Order
1. DBマイグレーション → データ移行 → キャッシュクリア
   (順番厳守)
2. 並列実行可能: 環境変数設定, Nginx設定更新
```

### 4. Prepare Rollback

```
✓ Good:
## Rollback Plan
- DBマイグレーション失敗時:
  1. `npx prisma migrate rollback`
  2. アプリケーション再デプロイ（前バージョン）
  3. キャッシュクリア
```

### 5. Track Time Estimates

```
✓ Good:
- [ ] データ移行スクリプト実行: `npm run migrate:data`
  - 所要時間: 約5分（10,000レコード）
  - 実行時間帯: 低トラフィック時推奨
```

## Common Patterns

### Pattern 1: Simple Migration

```markdown
# Post-Merge Tasks: add-user-role

## Status: pending

## Tasks

### Database Migrations
- [ ] マイグレーション実行: `npx prisma migrate deploy`
  - 対象: users テーブルに role カラム追加
  - デフォルト: 'user'

## Verification
- [ ] テーブル確認: `SELECT * FROM users LIMIT 1;`
```

### Pattern 2: Complex Deployment

```markdown
# Post-Merge Tasks: api-v2-release

## Status: pending

## Tasks

### Database Migrations
- [ ] スキーママイグレーション: `npm run migrate:schema`
- [ ] データ移行: `npm run migrate:data:v1-to-v2`
  - 所要時間: 約15分
  - バックアップ: `npm run backup:users`

### Environment Variables
- [ ] `API_VERSION`: `v2`
- [ ] `FEATURE_V2_ENABLED`: `true`
- [ ] `V1_DEPRECATION_DATE`: `2025-03-01`

### Deployment
- [ ] Blue-Green切り替え: `kubectl apply -f k8s/v2/`
- [ ] ヘルスチェック: `curl https://api.example.com/health`

### Configuration
- [ ] Nginx設定: `/etc/nginx/sites-available/api.conf`
  - 追加: `/api/v2` ルーティング
  - 再起動: `sudo systemctl reload nginx`

## Execution Order
1. バックアップ取得
2. DBマイグレーション（スキーマ → データ）
3. 環境変数設定
4. デプロイ（Blue環境）
5. ヘルスチェック
6. Nginx設定更新
7. トラフィック切り替え（Green → Blue）
8. 旧環境監視（24時間）

## Rollback Plan
- Phase 1失敗（DB）: バックアップから復元
- Phase 2失敗（デプロイ）: Blue環境削除、Green維持
- Phase 3失敗（Nginx）: 設定ロールバック
```

### Pattern 3: External Service Integration

```markdown
# Post-Merge Tasks: stripe-webhook-integration

## Status: pending

## Tasks

### Environment Variables
- [ ] `STRIPE_WEBHOOK_SECRET`: [ダッシュボードから取得]
  - 場所: .env.production

### External Services
- [ ] Stripe Webhook設定
  - URL: `https://api.example.com/webhooks/stripe`
  - イベント:
    - `checkout.session.completed`
    - `payment_intent.succeeded`
    - `payment_intent.failed`
  - アクセス: https://dashboard.stripe.com/webhooks

### Deployment
- [ ] Webhook エンドポイントデプロイ確認
  - テスト: Stripe CLI で送信
  - 検証: ログで受信確認

## Verification
- [ ] テストWebhook送信: `stripe trigger checkout.session.completed`
- [ ] ログ確認: `kubectl logs -l app=api | grep webhook`
- [ ] データベース確認: 支払い情報が正しく保存されているか
```

## Task File Lifecycle

```
┌─────────────────────────────────────────┐
│  PR作成時: pending                      │
│  - タスクファイル作成                   │
│  - PR説明にセクション追加               │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  PRマージ: in-progress                  │
│  - タスク実行開始                       │
│  - 各タスクにチェックマーク             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  全タスク完了: completed                │
│  - 完了日時記録                         │
│  - 検証実施                             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  アーカイブ: archived (オプション)      │
│  - archive/ フォルダに移動              │
│  - 参考資料として保持                   │
└─────────────────────────────────────────┘
```

## Integration with Other Skills

### With `context-preservation`

マージ後タスクをコンテキストとして保存。

```markdown
## 作業状態
- PR作成: #123
- Post-merge tasks: docs/post-merge-tasks/feature-auth.md
  - DBマイグレーション
  - 環境変数設定

## 再開時の注意点
- PRマージ後にタスク実行必須
```

### With `dev-workflow`

フェーズ7（Deployment/Review）でタスクファイル作成。

```
Phase 7: Deployment/Review
  ↓
Identify post-merge tasks
  ↓
Create task file
  ↓
Add to PR description
  ↓
Submit PR
```

### With `context-circulation`

チーム間でタスク情報を共有。

```
SendMessage:
  recipient: "deployment-team"
  content: |
    PR #123 merged
    Post-merge tasks: docs/post-merge-tasks/feature-auth.md
    - DBマイグレーション必要
    - 環境変数追加
  summary: "Post-merge tasks for PR #123"
```

## Completion Criteria

タスクファイルは以下を満たすべき:

```
[ ] すべてのタスクが具体的なコマンドを含む
[ ] 実行順序が明確
[ ] 検証方法が定義されている
[ ] ロールバック手順が記載されている
[ ] 所要時間の見積もりがある（大規模タスク）
[ ] 影響範囲が明記されている
[ ] PR説明にセクションが追加されている
```

## Red Flags

| Thought | Reality |
|---------|---------|
| "マージ後に考えればいい" | 実行漏れやトラブルの原因 |
| "簡単だから記録不要" | 数ヶ月後には忘れている |
| "口頭で伝えればOK" | 記録がないと引き継げない |
| "コマンドだけでいい" | なぜ必要かが不明だと実行されない |
| "ロールバック不要" | 失敗時に対処できない |

## Important

- **PR作成前に必ずタスクファイルを作成**
- **すべてのタスクに実行可能なコマンドを記載**
- **検証方法とロールバック手順を必ず含める**
- 実行順序を明確にする
- 所要時間を見積もる（大規模タスク）
- 影響範囲を明記する
- チームメンバーが読んで実行できるレベルで記述
- マージ後速やかに実行する
- 完了したら必ず検証する
- タスクファイルをバージョン管理に含める
