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

# このプラグインのリポジトリ内でのみ動作（他プロジェクトではスキップ）
CURRENT_REPO=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
RESOLVED_CURRENT=$(cd "$CURRENT_REPO" 2>/dev/null && pwd -P || echo "")
RESOLVED_SOURCE_CHECK=$(cd "$SOURCE_DIR" 2>/dev/null && pwd -P || echo "")
if [[ -z "$CURRENT_REPO" ]] || [[ "$RESOLVED_CURRENT" != "$RESOLVED_SOURCE_CHECK" ]]; then
    echo "  SKIP: not in fractal-dev-workflow repo (current: $RESOLVED_CURRENT)" >> "$LOG_FILE"
    exit 0
fi

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

# temp_gitキャッシュのクリーンアップ
# Claude Codeがtemp_git_*にクローンするとskills/docs以外のファイルが削除されるため除去する
for d in "$HOME/.claude/plugins/cache"/temp_git_*; do
    if [[ -d "$d" ]] && [[ "$(jq -r '.name // empty' "$d/.claude-plugin/plugin.json" 2>/dev/null)" == "fractal-dev-workflow" ]]; then
        rm -rf "$d"
        echo "  cleaned temp_git cache: $(basename "$d")" >> "$LOG_FILE"
    fi
done

# installed_plugins.json更新関数
update_installed_plugins() {
    local install_path="$1"
    local git_sha="$2"
    local now="$3"
    local installed_plugins="$HOME/.claude/plugins/installed_plugins.json"
    local plugin_key="${PLUGIN_NAME}@${MARKETPLACE}"

    local entry
    entry=$(jq -n \
        --arg scope "user" \
        --arg install_path "$install_path" \
        --arg version "$VERSION" \
        --arg now "$now" \
        --arg git_sha "$git_sha" \
        '{scope: $scope, installPath: $install_path, version: $version, installedAt: $now, lastUpdated: $now, gitCommitSha: $git_sha}')

    if [[ ! -f "$installed_plugins" ]]; then
        # ファイルが存在しない場合は新規作成
        jq -n \
            --arg key "$plugin_key" \
            --argjson entry "$entry" \
            '{version: 2, plugins: {($key): [$entry]}}' \
            > "$installed_plugins" 2>> "$LOG_FILE"
        echo "  installed_plugins.json created with $plugin_key" >> "$LOG_FILE"
    else
        # ファイルが存在する場合はエントリを追加または更新
        local tmp_file
        tmp_file=$(mktemp)
        jq \
            --arg key "$plugin_key" \
            --argjson entry "$entry" \
            '.plugins[$key] = [$entry]' \
            "$installed_plugins" > "$tmp_file" 2>> "$LOG_FILE"
        if [[ $? -eq 0 ]] && [[ -s "$tmp_file" ]]; then
            mv "$tmp_file" "$installed_plugins"
            echo "  installed_plugins.json updated: $plugin_key" >> "$LOG_FILE"
        else
            rm -f "$tmp_file"
            echo "  ERROR: failed to update installed_plugins.json" >> "$LOG_FILE"
        fi
    fi
}

INSTALL_PATH="$CACHE_DIR/$VERSION"
GIT_SHA=$(git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null || echo "unknown")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 既にシンボリックリンクなら installed_plugins.json の更新のみ行ってスキップ
if [[ -L "$CACHE_DIR/$VERSION" ]]; then
    echo "  SKIP: already symlinked" >> "$LOG_FILE"
    update_installed_plugins "$INSTALL_PATH" "$GIT_SHA" "$NOW"
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

# installed_plugins.json の更新
update_installed_plugins "$INSTALL_PATH" "$GIT_SHA" "$NOW"
