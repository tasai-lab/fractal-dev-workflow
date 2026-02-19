---
name: plugin-reinstall
description: プラグインの再インストールとトラブルシューティング
---

# プラグイン再インストール

## 自動修復

SessionEnd時に `reinstall-plugin.sh` が自動実行され、以下を行う:
- fractal-dev-workflow関連のtemp_gitキャッシュを削除
- キャッシュディレクトリにソースへのシンボリックリンクを作成
- `installed_plugins.json` にエントリを追加/更新

通常はセッション終了→再起動で自動復旧する。

## 手動トラブルシューティング

### 健全性チェック

```bash
bash ~/.claude/plugins/local/fractal-dev-workflow/scripts/plugin-health-check.sh
```

### よくある問題

| 症状 | 原因 | 対処 |
|------|------|------|
| `/plugins` で "failed to load" | `plugin.json` が空 or キャッシュ破損 | 下記の手動修復を実行 |
| `/plugins` に表示されない | `installed_plugins.json` にエントリなし | reinstall-plugin.sh を手動実行 |
| スキル/フックが動かない | シンボリックリンク切れ | ローカルリンクを再作成 |

### 手動修復ワンライナー

```bash
# 変数準備
PLUGIN_DIR=$(readlink ~/.claude/plugins/local/fractal-dev-workflow)
VERSION=$(jq -r '.version' "$PLUGIN_DIR/.claude-plugin/plugin.json")

# temp_gitキャッシュ削除
for d in ~/.claude/plugins/cache/temp_git_*; do grep -q "fractal-dev-workflow" "$d/CHANGELOG.md" 2>/dev/null && rm -rf "$d"; done

# キャッシュにシンボリックリンク作成
rm -rf ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow
mkdir -p ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow
ln -s "$PLUGIN_DIR" ~/.claude/plugins/cache/fractal-marketplace/fractal-dev-workflow/"$VERSION"
```

修復後、Claude Codeを再起動して確認。

### plugin.jsonが空の場合

```bash
cat > ~/.claude/plugins/local/fractal-dev-workflow/.claude-plugin/plugin.json << 'PJSON'
{
  "name": "fractal-dev-workflow",
  "version": "0.10.3",
  "description": "9フェーズワークフロー、サブエージェント駆動実装を提供する自律開発支援プラグイン",
  "author": { "name": "t.asai" },
  "keywords": ["workflow", "development", "codex", "subagent"]
}
PJSON
```

バージョンはCHANGELOG.mdの最新に合わせること。
