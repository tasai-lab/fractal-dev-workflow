# Post-Merge Tasks: add-user-email-verification

## Status: pending

## Merge Info
- Branch: feature/add-user-email-verification
- Base: main
- Created: 2025-02-15
- PR: #123
- Merged: (未マージ)
- Completed: (未完了)

## Tasks

### Database Migrations
- [ ] DBマイグレーション実行: `npx prisma migrate deploy`
  - 対象: users テーブルに email_verified カラム追加
  - 影響: 既存ユーザーはデフォルト false
  - 所要時間: 約10秒

### Environment Variables
- [ ] 環境変数設定: `EMAIL_VERIFICATION_ENABLED`
  - 値: `true`
  - 場所: .env.production
  - 影響: メール認証機能の有効化

## Execution Notes

### Pre-execution Checklist
- [ ] 本番環境へのアクセス確認
- [ ] DBバックアップ取得済み
- [ ] メール送信サービス動作確認

### Execution Order
1. DBマイグレーション
2. 環境変数設定
3. アプリケーション再起動
4. 検証

### Rollback Plan
- マイグレーション失敗時: `npx prisma migrate rollback`
- 環境変数設定失敗時: 変数削除して再起動

### Verification
- [ ] テーブル確認: `SELECT email_verified FROM users LIMIT 5;`
- [ ] 環境変数確認: `echo $EMAIL_VERIFICATION_ENABLED`
- [ ] 新規ユーザー登録テスト
- [ ] メール送信確認

## Notes
<!-- 実行時の追加メモ -->
