#!/bin/bash
# check-docs.sh - ドキュメント更新チェック（git push前）
# Claude Code PreToolUse フックとして動作

# 入力をJSONとして受け取る（Claude Codeがstdinで渡す）
INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/workflow-lib.sh" 2>/dev/null || true

# Bashツール以外は無視
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# コマンドを取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# git push でないなら無視
if ! echo "$COMMAND" | grep -qE 'git\s+push'; then
    exit 0
fi

# mainブランチへのpushか確認
if echo "$COMMAND" | grep -qE 'git\s+push.*\b(main|master|origin\s+main|origin\s+master)\b'; then
    IS_MAIN_PUSH=true
else
    # 引数なしのgit pushで現在のブランチがmainの場合
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]] && ! echo "$COMMAND" | grep -qE 'origin\s+\w+'; then
        IS_MAIN_PUSH=true
    else
        IS_MAIN_PUSH=false
    fi
fi

if [[ "$IS_MAIN_PUSH" != "true" ]]; then
    exit 0
fi

# バージョン自動更新（fractal-dev-workflow リポジトリのpush時のみ）
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
PLUGIN_ROOT=$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd -P)

if [[ "$REPO_ROOT" == "$PLUGIN_ROOT" ]]; then
    PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
    if [[ -f "$PLUGIN_JSON" ]]; then
        CURRENT_VERSION=$(jq -r '.version' "$PLUGIN_JSON" 2>/dev/null || echo "0.0.0")

        # 直近コミットがバージョンバンプなら二重バンプ防止
        LAST_MSG=$(git log -1 --format="%s" 2>/dev/null || echo "")
        if [[ "$LAST_MSG" != chore:\ bump\ version* ]]; then
            # リモートとの差分コミットを取得
            REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
            if [[ -n "$REMOTE_BRANCH" ]]; then
                COMMITS=$(git log "$REMOTE_BRANCH"..HEAD --format="%s" 2>/dev/null)
            else
                COMMITS=$(git log -20 --format="%s" 2>/dev/null)
            fi

            if [[ -n "$COMMITS" ]]; then
                # conventional commits からバンプタイプ判定
                BUMP_TYPE="patch"
                if echo "$COMMITS" | grep -qiE 'BREAKING CHANGE|^[a-z]+!\(|^[a-z]+!:'; then
                    BUMP_TYPE="major"
                elif echo "$COMMITS" | grep -qiE '^feat'; then
                    BUMP_TYPE="minor"
                fi

                # バージョン計算
                IFS='.' read -r V_MAJOR V_MINOR V_PATCH <<< "$CURRENT_VERSION"
                case "$BUMP_TYPE" in
                    major) V_MAJOR=$((V_MAJOR + 1)); V_MINOR=0; V_PATCH=0 ;;
                    minor) V_MINOR=$((V_MINOR + 1)); V_PATCH=0 ;;
                    patch) V_PATCH=$((V_PATCH + 1)) ;;
                esac
                NEW_VERSION="${V_MAJOR}.${V_MINOR}.${V_PATCH}"

                # plugin.json + installed_plugins.json 更新 + コミット
                if [[ "$NEW_VERSION" != "$CURRENT_VERSION" ]]; then
                    jq --arg v "$NEW_VERSION" '.version = $v' "$PLUGIN_JSON" > "${PLUGIN_JSON}.tmp" && mv "${PLUGIN_JSON}.tmp" "$PLUGIN_JSON"
                    git add "$PLUGIN_JSON" 2>/dev/null

                    # installed_plugins.json のバージョンも同期
                    INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"
                    PLUGIN_KEY="fractal-dev-workflow@fractal-marketplace"
                    if [[ -f "$INSTALLED_JSON" ]]; then
                        COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "")
                        UPDATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
                        jq --arg v "$NEW_VERSION" --arg sha "$COMMIT_SHA" --arg ts "$UPDATED_AT" --arg key "$PLUGIN_KEY" \
                            '.plugins[$key][0].version = $v | .plugins[$key][0].gitCommitSha = $sha | .plugins[$key][0].lastUpdated = $ts' \
                            "$INSTALLED_JSON" > "${INSTALLED_JSON}.tmp" && mv "${INSTALLED_JSON}.tmp" "$INSTALLED_JSON"
                        hook_log "check-docs" "installed_plugins.json synced to $NEW_VERSION"
                    fi

                    git commit -m "chore: bump version to $NEW_VERSION" 2>/dev/null
                    hook_log "check-docs" "version bumped: $CURRENT_VERSION -> $NEW_VERSION ($BUMP_TYPE)"
                fi
            fi
        fi
    fi
fi

# mainへのpush: ドキュメントチェック
WARNINGS=""

# 1. CHANGELOGが更新されているか（origin/mainとの差分で判定）
REMOTE_REF=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
if [[ -n "$REMOTE_REF" ]]; then
    CHANGELOG_CHANGED=$(git diff "$REMOTE_REF" --name-only 2>/dev/null | grep -c "CHANGELOG.md" || true)
    if [[ "$CHANGELOG_CHANGED" -eq 0 ]]; then
        CHANGELOG_IN_COMMITS=$(git log "$REMOTE_REF"..HEAD --name-only --format="" 2>/dev/null | grep -c "CHANGELOG.md" || true)
        if [[ "$CHANGELOG_IN_COMMITS" -eq 0 ]]; then
            WARNINGS="${WARNINGS}\n- CHANGELOG.md が更新されていません"
        fi
    fi
fi

# 2. docs/workflow-flow.md が存在するか
if [[ ! -f "docs/workflow-flow.md" ]]; then
    WARNINGS="${WARNINGS}\n- docs/workflow-flow.md が存在しません"
fi

# 警告がある場合: hookSpecificOutput形式でdenyを返す
if [[ -n "$WARNINGS" ]]; then
    WARN_MSG=$(echo -e "$WARNINGS")
    jq -n --arg reason "mainへのpush前にドキュメントを確認してください:${WARN_MSG}" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
fi

exit 0
