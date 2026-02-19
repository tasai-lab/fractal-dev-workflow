#!/bin/bash
# reinstall-plugin.sh - SessionEnd hook
# セッション終了時にプラグインキャッシュをシンボリックリンクに置き換え、
# 次回セッションで最新の変更が反映されるようにする

# stdin読み取り（フックプロトコル）
cat > /dev/null

LOG_FILE="/tmp/fractal-reinstall-plugin.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') reinstall-plugin.sh triggered" >> "$LOG_FILE"

PLUGIN_NAME="fractal-dev-workflow"
MARKETPLACE="fractal-marketplace"
CACHE_DIR="$HOME/.claude/plugins/cache/$MARKETPLACE/$PLUGIN_NAME"
SOURCE_DIR="${CLAUDE_PLUGIN_ROOT:-/Users/t.asai/code/fractal-dev-workflow}"
VERSION=$(cat "$SOURCE_DIR/.claude-plugin/plugin.json" 2>/dev/null | jq -r '.version // "0.4.0"')

echo "  CACHE_DIR=$CACHE_DIR VERSION=$VERSION SOURCE_DIR=$SOURCE_DIR" >> "$LOG_FILE"

# ソースディレクトリが存在しなければ何もしない
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "  SKIP: SOURCE_DIR not found" >> "$LOG_FILE"
    exit 0
fi

# 既にシンボリックリンクなら何もしない
if [[ -L "$CACHE_DIR/$VERSION" ]]; then
    echo "  SKIP: already symlinked" >> "$LOG_FILE"
    exit 0
fi

# キャッシュをクリアしてシンボリックリンクを作成
rm -rf "$CACHE_DIR"
mkdir -p "$CACHE_DIR"
ln -s "$SOURCE_DIR" "$CACHE_DIR/$VERSION"
echo "  DONE: symlink created at $CACHE_DIR/$VERSION -> $SOURCE_DIR" >> "$LOG_FILE"
