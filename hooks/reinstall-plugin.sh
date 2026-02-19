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
# SOURCE_DIR はローカルプラグインのシンボリックリンクから解決する
# CLAUDE_PLUGIN_ROOT はキャッシュパス自体を返すため使用しない
LOCAL_PLUGIN="$HOME/.claude/plugins/local/$PLUGIN_NAME"
if [[ -L "$LOCAL_PLUGIN" ]]; then
    SOURCE_DIR=$(readlink "$LOCAL_PLUGIN")
else
    # フォールバック: スクリプト自身の位置から解決
    SCRIPT_DIR_FALLBACK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SOURCE_DIR="$(cd "$SCRIPT_DIR_FALLBACK/.." && pwd)"
fi
VERSION=$(cat "$SOURCE_DIR/.claude-plugin/plugin.json" 2>/dev/null | jq -r '.version // "0.4.0"')

echo "  CACHE_DIR=$CACHE_DIR VERSION=$VERSION SOURCE_DIR=$SOURCE_DIR" >> "$LOG_FILE"

# ソースディレクトリが存在しなければ何もしない
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "  SKIP: SOURCE_DIR not found" >> "$LOG_FILE"
    exit 0
fi

# 自己参照防止: SOURCE_DIR がキャッシュパス内を指していないか検証
RESOLVED_SOURCE=$(cd "$SOURCE_DIR" 2>/dev/null && pwd -P)
if [[ "$RESOLVED_SOURCE" == *"/.claude/plugins/cache/"* ]]; then
    echo "  ERROR: SOURCE_DIR resolves to cache path ($RESOLVED_SOURCE). Aborting." >> "$LOG_FILE"
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

# シンボリックリンクの検証
LINK_TARGET=$(readlink "$CACHE_DIR/$VERSION")
if [[ "$LINK_TARGET" != "$SOURCE_DIR" ]]; then
    echo "  ERROR: symlink verification failed. Expected $SOURCE_DIR, got $LINK_TARGET" >> "$LOG_FILE"
    rm -f "$CACHE_DIR/$VERSION"
    exit 1
fi
if [[ ! -d "$CACHE_DIR/$VERSION/hooks" ]]; then
    echo "  ERROR: hooks directory not found at $CACHE_DIR/$VERSION/hooks" >> "$LOG_FILE"
    exit 1
fi
echo "  DONE: symlink created and verified at $CACHE_DIR/$VERSION -> $SOURCE_DIR" >> "$LOG_FILE"
