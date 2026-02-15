# Post-Merge Tasks: api-v2-migration

## Status: pending

## Merge Info
- Branch: feature/api-v2-migration
- Base: main
- Created: 2025-02-15
- PR: #456
- Merged: (未マージ)
- Completed: (未完了)

## Tasks

### Database Migrations
- [ ] スキーママイグレーション: `npm run migrate:schema`
  - 対象: api_endpoints テーブルに version カラム追加
  - 影響: 既存エンドポイントは v1 として記録
  - 所要時間: 約30秒

- [ ] データ移行: `npm run migrate:data:v1-to-v2`
  - 内容: 旧形式のレスポンスを新形式に変換
  - 対象レコード数: 約50,000件
  - 所要時間: 約10分
  - バックアップ: 実行前に必ず `npm run backup:api-data` を実行

### Environment Variables
- [ ] `API_VERSION`: `v2`
  - 場所: .env.production
  - 影響: デフォルトAPIバージョン切り替え

- [ ] `API_V1_DEPRECATION_DATE`: `2025-03-31`
  - 場所: .env.production
  - 影響: v1非推奨アラート表示開始日

- [ ] `FEATURE_V2_RATE_LIMIT`: `1000`
  - 場所: .env.production
  - 影響: v2エンドポイントのレート制限（リクエスト/時間）

### Deployment
- [ ] Blue-Green デプロイ: `kubectl apply -f k8s/v2/deployment.yaml`
  - 理由: ダウンタイムゼロでのリリース
  - 検証: `kubectl get pods -l version=v2`

- [ ] ヘルスチェック: `curl https://api.example.com/v2/health`
  - 期待値: `{"status": "ok", "version": "2.0.0"}`
  - タイムアウト: 30秒

- [ ] メトリクス監視: Datadog ダッシュボード確認
  - URL: https://app.datadoghq.com/dashboard/abc-123
  - 確認項目: レスポンスタイム、エラーレート、スループット

### Configuration
- [ ] Nginx設定更新: `/etc/nginx/sites-available/api.conf`
  - 追加:
    ```nginx
    location /api/v2 {
        proxy_pass http://backend-v2;
        proxy_set_header X-API-Version "2";
    }
    ```
  - 再起動: `sudo nginx -t && sudo systemctl reload nginx`

- [ ] CDN設定更新: Cloudflare
  - URL: https://dash.cloudflare.com/
  - 設定: `/api/v2/*` をキャッシュ対象に追加
  - TTL: 300秒

### External Services
- [ ] Datadog メトリクス設定
  - ダッシュボード: API v2 Performance
  - メトリクス追加:
    - `api.v2.requests.count`
    - `api.v2.requests.duration`
    - `api.v2.errors.count`
  - アラート設定: エラーレート > 5%

- [ ] Sentry プロジェクト設定
  - 新規環境追加: `production-v2`
  - Release tracking有効化
  - Source maps アップロード: `npm run sentry:upload-sourcemaps`

### Custom
- [ ] APIドキュメント更新: `npm run docs:generate`
  - 出力先: `docs/api/v2/`
  - デプロイ: `npm run docs:deploy`
  - URL: https://docs.example.com/api/v2

- [ ] v1非推奨通知メール送信: `npm run notify:v1-deprecation`
  - 対象: API利用中のすべての顧客
  - テンプレート: `templates/email/v1-deprecation.html`
  - 送信前確認: テストメールをチーム内に送信

## Execution Notes

### Pre-execution Checklist
- [ ] 本番環境バックアップ取得
  - DB: `pg_dump`
  - Redis: `redis-cli BGSAVE`
  - 設定ファイル: `/etc/nginx/`, `/etc/systemd/`
- [ ] 依存タスクの完了確認
  - [ ] v2エンドポイントのE2Eテスト通過
  - [ ] セキュリティスキャン完了
  - [ ] パフォーマンステスト通過
- [ ] 実行環境の確認
  - [ ] Kubernetes クラスタ正常
  - [ ] 十分なリソース (CPU: 50%, Memory: 60%)
  - [ ] ディスク容量: 30% 以上空き
- [ ] ロールバック手順の準備
  - [ ] v1デプロイメントYAMLを保持
  - [ ] DB ロールバックスクリプト準備
  - [ ] チーム連絡体制確認

### Execution Order

**Phase 1: 準備（15分）**
1. バックアップ取得
2. Blue環境準備
3. 監視ツール確認

**Phase 2: データベース（15分）**
1. スキーママイグレーション
2. データ移行スクリプト実行
3. データ整合性チェック

**Phase 3: デプロイ（20分）**
1. Blue環境にv2デプロイ
2. ヘルスチェック
3. スモークテスト実行

**Phase 4: 設定変更（10分）**
1. 環境変数設定
2. Nginx設定更新
3. CDN設定更新

**Phase 5: 外部サービス（10分）**
1. Datadog設定
2. Sentry設定
3. メトリクス確認

**Phase 6: トラフィック切り替え（10分）**
1. 10% トラフィック → Blue (v2)
2. 監視（5分）
3. 問題なければ 50% → Blue
4. 監視（5分）
5. 問題なければ 100% → Blue

**Phase 7: 後処理（15分）**
1. ドキュメント更新
2. 非推奨通知メール送信
3. Green環境（v1）スケールダウン（削除はしない）

**合計所要時間: 約95分**

### Rollback Plan

**Phase 1-2 失敗（データベース）:**
1. データ移行スクリプト停止: `kill -INT <pid>`
2. DBロールバック: `npm run migrate:rollback`
3. バックアップから復元: `pg_restore`
4. 整合性チェック: `npm run db:verify`

**Phase 3 失敗（デプロイ）:**
1. Blue環境削除: `kubectl delete -f k8s/v2/`
2. Green環境（v1）維持
3. ログ収集: `kubectl logs -l version=v2`

**Phase 4-5 失敗（設定変更）:**
1. Nginx設定ロールバック: `git checkout nginx.conf.backup`
2. 再起動: `sudo systemctl reload nginx`
3. CDN設定を元に戻す

**Phase 6 失敗（トラフィック切り替え）:**
1. トラフィック 100% → Green (v1)
2. Blue環境調査・修正
3. 修正後、Phase 6を再実行

**緊急時:**
- トラフィック即座に v1 へ: `kubectl set image deployment/api api=api:v1`
- 監視ダッシュボード: https://app.datadoghq.com/dashboard/emergency
- エスカレーション: Slack #incidents チャンネル

### Verification

**データベース:**
- [ ] スキーマ確認: `SELECT column_name FROM information_schema.columns WHERE table_name='api_endpoints';`
- [ ] データ件数確認: `SELECT version, COUNT(*) FROM api_endpoints GROUP BY version;`
- [ ] データ整合性: `npm run db:verify:v2-migration`

**デプロイメント:**
- [ ] Pod 状態: `kubectl get pods -l app=api,version=v2`
  - すべて Running かつ Ready
- [ ] ヘルスチェック: `curl -f https://api.example.com/v2/health`
  - HTTP 200 OK
- [ ] バージョン確認: `curl https://api.example.com/v2/version`
  - `{"version": "2.0.0"}`

**エンドポイント:**
- [ ] v2エンドポイントテスト:
  ```bash
  curl -X POST https://api.example.com/v2/users \
    -H "Content-Type: application/json" \
    -d '{"name": "Test User"}'
  ```
  - レスポンス形式が v2 仕様に準拠

**パフォーマンス:**
- [ ] レスポンスタイム: p95 < 200ms
- [ ] エラーレート: < 0.1%
- [ ] スループット: > 1000 req/sec

**設定:**
- [ ] Nginx設定: `sudo nginx -t`
  - syntax is ok
- [ ] 環境変数: `printenv | grep API_`
  - すべての変数が正しく設定されている

**監視:**
- [ ] Datadog メトリクス表示確認
- [ ] Sentry エラー収集確認
- [ ] ログ出力確認: `kubectl logs -l app=api,version=v2 | head -n 50`

**ユーザー通知:**
- [ ] ドキュメントサイト更新確認: https://docs.example.com/api/v2
- [ ] 非推奨通知メール送信確認: 送信ログを確認

## Notes

### 2025-02-15 12:00 - 実行開始
- Phase 1完了: バックアップ取得済み
- Phase 2進行中: データ移行に予想より時間がかかっている（15分経過、50%完了）

### 2025-02-15 12:30 - Phase 2完了
- データ移行完了: 所要時間 25分（予定より15分超過）
- 原因: レコード数が予想より多かった（80,000件）
- 次回への改善: バッチサイズを調整すべき

### 2025-02-15 13:00 - トラフィック切り替え完了
- 10% → 50% → 100% の切り替え成功
- エラーレート: 0.05% (正常範囲)
- レスポンスタイム: p95 = 180ms (目標達成)

### 2025-02-15 13:30 - 全タスク完了
- すべての検証項目クリア
- Green環境（v1）はスケールダウンのみ（削除せず7日間保持）
- 監視継続: 24時間体制で異常検知
