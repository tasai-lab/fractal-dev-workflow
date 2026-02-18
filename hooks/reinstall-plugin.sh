#!/bin/bash
# reinstall-plugin.sh - Stop hook
# セッション終了時にプラグインキャッシュをシンボリックリンクに置き換え、
# 次回セッションで最新の変更が反映されるようにする

PLUGIN_NAME="fractal-dev-workflow"
MARKETPLACE="fractal-marketplace"
CACHE_DIR="$HOME/.claude/plugins/cache/$MARKETPLACE/$PLUGIN_NAME"
SOURCE_DIR="/Users/t.asai/code/fractal-dev-workflow"
VERSION=$(cat "$SOURCE_DIR/.claude-plugin/plugin.json" 2>/dev/null | jq -r '.version // "0.4.0"')

# ソースディレクトリが存在しなければ何もしない
if [[ ! -d "$SOURCE_DIR" ]]; then
    exit 0
fi

# 既にシンボリックリンクなら何もしない
if [[ -L "$CACHE_DIR/$VERSION" ]]; then
    exit 0
fi

# キャッシュをクリアしてシンボリックリンクを作成
rm -rf "$CACHE_DIR"
mkdir -p "$CACHE_DIR"
ln -s "$SOURCE_DIR" "$CACHE_DIR/$VERSION"
