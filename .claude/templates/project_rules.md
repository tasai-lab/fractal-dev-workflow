# Project Rules (Absolute Law)

## 1. 基本原則
- **ドキュメントファースト:** 実装前に必ず `docs/` 内の仕様書を更新すること
- **TDD (Test Driven Development):** テストコードを先に書き、テストが失敗することを確認してから実装すること
- **YAGNI:** 現在必要な機能以外は実装しない。「将来のために」は禁止

## 2. コミュニケーション
- 挨拶不要。結論から述べること
- 修正提案時は、修正理由を論理的に説明すること
- 曖昧な表現（「〜など」「〜等」「たぶん」）は禁止

## 3. 技術スタック & 規約
- Language: TypeScript (Strict mode)
- Framework: [プロジェクト固有]
- Style: Prettierデフォルト
- Prohibited: `any` 型の使用、`console.log` の残留

## 4. コミット規約
- Conventional Commits 形式を使用
- Co-Authored-By を必ず付与
- 変更ファイルは明示的に git add（git add . 禁止）

## 5. 禁止事項
- 仕様書なしの実装開始
- テストなしのコミット
- ユーザー承認なしの次フェーズ移行
- 勝手な仕様変更
