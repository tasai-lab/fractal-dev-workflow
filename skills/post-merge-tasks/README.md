# Post-Merge Tasks Skill

PR作成時にマージ後に必要なタスクを収集し、実行可能な形式で記録するスキル。

## 概要

PRマージ後に実行すべきタスク（DBマイグレーション、環境変数設定、デプロイ作業等）を構造化して記録し、実行漏れを防ぎます。

## 使い方

### 1. PR作成前にタスクファイルを作成

```bash
# タスクファイルを作成
touch docs/post-merge-tasks/{branch-name}.md

# テンプレートをコピー（SKILL.mdから）
# または example-simple.md / example-complex.md を参考に作成
```

### 2. タスクを記録

タスクカテゴリに従って、実行すべきタスクを記録します。

**必須項目:**
- 具体的なコマンド
- 実行理由・影響範囲
- 検証方法
- ロールバック手順（大規模変更の場合）

### 3. PR説明にセクションを追加

```markdown
## Post-Merge Tasks

マージ後に以下のタスクを実行してください:

- [ ] DBマイグレーション: `npm run migrate`
- [ ] 環境変数 `NEW_FEATURE_ENABLED` を設定

> 詳細: [docs/post-merge-tasks/{branch-name}.md](./docs/post-merge-tasks/{branch-name}.md)
> `/post-merge` コマンドで実行可能（将来実装予定）
```

### 4. PRマージ後にタスクを実行

```bash
# タスクファイルを参照
cat docs/post-merge-tasks/{branch-name}.md

# 記載された順序でタスクを実行
npm run migrate
# ...

# 完了したらチェックマーク
# - [x] DBマイグレーション: `npm run migrate`
```

### 5. 検証と完了

```bash
# すべてのタスクを実行後、検証
# Verification セクションに記載された手順に従う

# ステータスを更新
## Status: pending → completed
- Completed: 2025-02-15

# コミット
git add docs/post-merge-tasks/{branch-name}.md
git commit -m "docs: post-merge tasks completed for {branch-name}"
```

## タスクカテゴリ

### Database Migrations
- スキーマ変更
- データ移行
- インデックス追加

### Environment Variables
- 新規環境変数追加
- 既存変数の値変更
- 環境別設定

### Deployment
- デプロイ設定変更
- インフラ更新
- スケーリング設定

### Configuration
- Nginx/Apache設定
- ロードバランサー設定
- CDN設定

### Data Migration
- 既存データの変換
- データクリーンアップ
- データバックアップ

### External Services
- Webhook設定
- API連携設定
- サードパーティサービス設定

### Custom
- その他カスタムタスク

## サンプルファイル

### Simple Example
[example-simple.md](./example-simple.md) - シンプルなマイグレーションと環境変数設定

### Complex Example
[example-complex.md](./example-complex.md) - 複雑なAPI v2移行プロジェクト

## ベストプラクティス

### 具体的なコマンドを記載
```
❌ Bad: データベース更新
✓ Good: DBマイグレーション: `npx prisma migrate deploy`
```

### 検証方法を含める
```
✓ Good:
- [ ] DBマイグレーション: `npm run migrate`
  - 検証: `SELECT * FROM users LIMIT 1;`
```

### 実行順序を明確に
```
✓ Good:
## Execution Order
1. バックアップ取得 → DBマイグレーション → 検証
2. 並列実行可能: 環境変数設定, Nginx設定
```

### ロールバック手順を準備
```
✓ Good:
## Rollback Plan
- DBマイグレーション失敗時: `npm run migrate:rollback`
```

## 将来の機能

### `/post-merge` コマンド（計画中）

```bash
# タスクファイル作成
/post-merge create

# タスク追加
/post-merge add "DBマイグレーション: npm run migrate"

# タスク実行
/post-merge exec migration

# 完了マーク
/post-merge done migration

# ステータス確認
/post-merge status
```

## 関連スキル

- `context-preservation`: マージ後タスクをコンテキストとして保存
- `dev-workflow`: Phase 7でタスクファイル作成
- `context-circulation`: チーム間でタスク情報を共有

## トラブルシューティング

### Q: タスクファイルはどこに保存すべき？
A: `docs/post-merge-tasks/` ディレクトリに `{branch-name}.md` として保存。

### Q: PRマージ前にタスクを実行してはいけない？
A: 原則、マージ後に実行。ただし、ステージング環境での事前検証は推奨。

### Q: タスクが多すぎる場合は？
A: カテゴリ別に整理し、実行順序を明確にする。並列実行可能なタスクを特定する。

### Q: ロールバックが必要になったら？
A: タスクファイルの「Rollback Plan」セクションに従って実行。

## ライセンス

このスキルは fractal-dev-workflow プロジェクトの一部です。
