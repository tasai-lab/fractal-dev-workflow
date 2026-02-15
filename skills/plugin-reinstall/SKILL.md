---
name: plugin-reinstall
description: プラグインの変更を反映するための再インストール手順
---

# プラグイン再インストール

## 概要

プラグインのスキル/エージェント/コマンドを変更した後、変更を反映するための手順。

## 手順

### 1. キャッシュをクリア

```bash
rm -rf ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow
```

### 2. シンボリックリンクを作成

```bash
mkdir -p ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow
ln -s /Users/t.asai/code/fractal-dev-workflow ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow/0.3.0
```

### 3. 確認

```bash
ls -la ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow/
```

期待される出力:
```
0.3.0 -> /Users/t.asai/code/fractal-dev-workflow
```

## ワンライナー

```bash
rm -rf ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow && mkdir -p ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow && ln -s /Users/t.asai/code/fractal-dev-workflow ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow/0.3.0
```

## 注意事項

- シンボリックリンク作成後、新しいClaude Codeセッションを開始すると変更が反映される
- 現在のセッションには反映されない
- バージョン番号（0.3.0）は `installed_plugins.json` の設定と一致させること

## 開発ワークフロー

1. スキル/エージェント/コマンドを編集
2. 変更をコミット・プッシュ
3. このスキルの手順でキャッシュを更新（初回のみ、以降はシンボリックリンクで自動反映）
4. 新しいセッションを開始して動作確認
