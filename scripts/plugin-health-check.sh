#!/bin/bash
# plugin-health-check.sh - プラグインの健全性チェック
# 使用方法: bash scripts/plugin-health-check.sh

PLUGIN_NAME="fractal-dev-workflow"
MARKETPLACE="fractal-marketplace"
ERRORS=0
WARNINGS=0

echo "=== fractal-dev-workflow Plugin Health Check ==="
echo ""

# 1. ローカルプラグインのシンボリックリンク確認
echo "[1/6] ローカルプラグイン..."
LOCAL_LINK="$HOME/.claude/plugins/local/$PLUGIN_NAME"
if [[ -L "$LOCAL_LINK" ]]; then
    TARGET=$(readlink "$LOCAL_LINK")
    if [[ -d "$TARGET" ]]; then
        echo "  OK: $LOCAL_LINK -> $TARGET"
    else
        echo "  ERROR: シンボリックリンクのターゲットが存在しない: $TARGET"
        ((ERRORS++))
    fi
else
    echo "  ERROR: ローカルプラグインが未インストール: $LOCAL_LINK"
    ((ERRORS++))
fi

# 2. キャッシュまたはinstallPath直接参照の確認
echo "[2/6] installPath..."
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
INSTALL_PATH=$(jq -r ".plugins[\"${PLUGIN_NAME}@${MARKETPLACE}\"][0].installPath // \"\"" "$INSTALLED" 2>/dev/null)
if [[ -n "$INSTALL_PATH" ]]; then
    if [[ "$INSTALL_PATH" == *"/.claude/plugins/cache/"* ]]; then
        # キャッシュ経由: シンボリックリンクの健全性確認
        if [[ -L "$INSTALL_PATH" ]]; then
            LINK_TARGET=$(readlink "$INSTALL_PATH")
            if [[ "$LINK_TARGET" == *"/.claude/plugins/cache/"* ]]; then
                echo "  ERROR: 自己参照シンボリックリンク検出: $INSTALL_PATH -> $LINK_TARGET"
                ((ERRORS++))
            elif [[ -d "$LINK_TARGET" ]]; then
                echo "  OK: キャッシュ経由 $INSTALL_PATH -> $LINK_TARGET"
            else
                echo "  ERROR: ターゲットが存在しない: $INSTALL_PATH -> $LINK_TARGET"
                ((ERRORS++))
            fi
        elif [[ -d "$INSTALL_PATH" ]]; then
            echo "  WARNING: キャッシュが実ディレクトリ（シンボリックリンクではない）: $INSTALL_PATH"
            ((WARNINGS++))
        else
            echo "  ERROR: installPathが存在しない: $INSTALL_PATH"
            ((ERRORS++))
        fi
    else
        # ソース直接参照
        if [[ -d "$INSTALL_PATH" ]]; then
            echo "  OK: ソース直接参照 ($INSTALL_PATH)"
        else
            echo "  ERROR: installPathが存在しない: $INSTALL_PATH"
            ((ERRORS++))
        fi
    fi
else
    echo "  ERROR: installed_plugins.jsonにエントリが見つからない"
    ((ERRORS++))
fi

# 3. フックスクリプトの存在と構文チェック
echo "[3/6] フックスクリプト..."
HOOKS_DIR=""
if [[ -L "$LOCAL_LINK" ]]; then
    HOOKS_DIR="$(readlink "$LOCAL_LINK")/hooks"
fi
if [[ -d "$HOOKS_DIR" ]]; then
    for hook in session-init.sh check-approval.sh check-docs.sh check-commit-context.sh reinstall-plugin.sh workflow-lib.sh; do
        if [[ -f "$HOOKS_DIR/$hook" ]]; then
            if bash -n "$HOOKS_DIR/$hook" 2>/dev/null; then
                echo "  OK: $hook"
            else
                echo "  ERROR: $hook (構文エラー)"
                ((ERRORS++))
            fi
        else
            echo "  ERROR: $hook が見つからない"
            ((ERRORS++))
        fi
    done
else
    echo "  ERROR: フックディレクトリが見つからない"
    ((ERRORS++))
fi

# 4. hooks.json の検証
echo "[4/6] hooks.json..."
if [[ -L "$LOCAL_LINK" ]]; then
    HOOKS_JSON="$(readlink "$LOCAL_LINK")/hooks/hooks.json"
    if [[ -f "$HOOKS_JSON" ]]; then
        if jq empty "$HOOKS_JSON" 2>/dev/null; then
            HOOK_COUNT=$(jq '[.hooks | to_entries[] | .value[] | .hooks[]?] | length' "$HOOKS_JSON" 2>/dev/null)
            echo "  OK: 有効なJSON ($HOOK_COUNT フック定義)"
        else
            echo "  ERROR: JSONパースエラー"
            ((ERRORS++))
        fi
    else
        echo "  ERROR: hooks.json が見つからない"
        ((ERRORS++))
    fi
fi

# 5. バージョン確認
echo "[5/6] バージョン..."
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"
if [[ -f "$INSTALLED" && -L "$LOCAL_LINK" ]]; then
    INSTALLED_VER=$(jq -r ".plugins[\"${PLUGIN_NAME}@${MARKETPLACE}\"][0].version // \"unknown\"" "$INSTALLED" 2>/dev/null)
    PLUGIN_JSON="$(readlink "$LOCAL_LINK")/.claude-plugin/plugin.json"
    PLUGIN_VER=$(jq -r '.version // "unknown"' "$PLUGIN_JSON" 2>/dev/null)
    if [[ "$INSTALLED_VER" == "$PLUGIN_VER" ]]; then
        echo "  OK: バージョン一致 ($INSTALLED_VER)"
    else
        echo "  WARNING: バージョン不一致 (installed: $INSTALLED_VER, plugin.json: $PLUGIN_VER)"
        ((WARNINGS++))
    fi
else
    echo "  SKIP: 確認不可"
fi

# 6. フックログの最新エラー確認
echo "[6/6] フックログ..."
for log in /tmp/fractal-hooks.log /tmp/fractal-reinstall-plugin.log; do
    if [[ -f "$log" ]]; then
        RECENT_ERRORS=$(tail -20 "$log" | grep -i "error" | tail -3)
        if [[ -n "$RECENT_ERRORS" ]]; then
            echo "  WARNING: $(basename $log) に最近のエラー:"
            echo "$RECENT_ERRORS" | while read -r line; do echo "    $line"; done
            ((WARNINGS++))
        else
            echo "  OK: $(basename $log)"
        fi
    fi
done

echo ""
echo "=== 結果: $ERRORS エラー, $WARNINGS 警告 ==="
exit $ERRORS
