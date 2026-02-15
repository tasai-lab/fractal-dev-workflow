# プラグイン再インストール手順

## 前提条件
- Claude Codeがインストールされていること
- プラグインのソースコードが `/Users/t.asai/code/fractal-dev-workflow` にあること

## 手順

### 1. プラグインをアンインストール
```bash
claude plugins uninstall fractal-dev-workflow
```

### 2. プラグインをインストール
```bash
claude plugins install /Users/t.asai/code/fractal-dev-workflow
```

### 3. インストール確認
```bash
claude plugins list
```

## 注意事項
- Claude Codeセッション内からは `claude plugins` コマンドを実行できない
- 別のターミナルで実行すること

## 開発時のワークフロー

1. スキル/エージェント/コマンドを編集
2. 変更をコミット・プッシュ
3. 別ターミナルでプラグインを再インストール
4. 新しいClaude Codeセッションを開始して動作確認
