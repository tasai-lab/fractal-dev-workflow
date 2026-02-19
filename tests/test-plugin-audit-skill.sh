#!/bin/bash
# test-plugin-audit-skill.sh - plugin-audit SKILL.md の存在とフォーマット検証

# errexit を無効化してアサーション失敗時もスクリプトを継続させる
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="$PROJECT_ROOT/skills/plugin-audit/SKILL.md"

# テストカウンター
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# アサーション関数
assert_true() {
    local description="$1"
    local condition="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if eval "$condition"; then
        echo "  PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  FAIL: $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_contains() {
    local description="$1"
    local file="$2"
    local pattern="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  FAIL: $description (pattern not found: $pattern)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_not_contains() {
    local description="$1"
    local file="$2"
    local pattern="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  PASS: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  FAIL: $description (pattern should not exist: $pattern)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

count_lines() {
    wc -l < "$1" | tr -d ' '
}

echo "=== plugin-audit SKILL.md フォーマット検証 ==="
echo ""

# 1. ファイル存在確認
echo "[Test Group 1] ファイル存在"
assert_true "SKILL.md ファイルが存在する" "[ -f '$SKILL_FILE' ]"
assert_true "skills/plugin-audit/ ディレクトリが存在する" "[ -d '$PROJECT_ROOT/skills/plugin-audit' ]"

echo ""

# 2. YAMLフロントマター確認
echo "[Test Group 2] YAMLフロントマター"
assert_contains "フロントマター開始 (---) が存在する" "$SKILL_FILE" "^---$"
assert_contains "name フィールドが存在する" "$SKILL_FILE" "^name: plugin-audit$"
assert_contains "description フィールドが存在する" "$SKILL_FILE" "^description:"

echo ""

# 3. 必須セクション確認
echo "[Test Group 3] 必須セクション"
assert_contains "H1見出し (# plugin-audit) が存在する" "$SKILL_FILE" "^# "
assert_contains "概要セクションが存在する" "$SKILL_FILE" "## Overview\|## 概要"
assert_contains "The Process セクションが存在する" "$SKILL_FILE" "## The Process"
assert_contains "dot図が存在する" "$SKILL_FILE" "digraph\|dot"
assert_contains "Steps セクションが存在する" "$SKILL_FILE" "## Steps\|## Step "
assert_contains "Completion Criteria セクションが存在する" "$SKILL_FILE" "## Completion Criteria"
assert_contains "Red Flags セクションが存在する" "$SKILL_FILE" "## Red Flags"

echo ""

# 4. 5カテゴリ評価内容確認
echo "[Test Group 4] 5カテゴリ評価"
assert_contains "Structure カテゴリが存在する" "$SKILL_FILE" "Structure"
assert_contains "Compliance カテゴリが存在する" "$SKILL_FILE" "Compliance"
assert_contains "Flow カテゴリが存在する" "$SKILL_FILE" "Flow"
assert_contains "Token カテゴリが存在する" "$SKILL_FILE" "Token"
assert_contains "Security カテゴリが存在する" "$SKILL_FILE" "Security"
assert_contains "合計スコア100点が記載されている" "$SKILL_FILE" "100"

echo ""

# 5. レポートフォーマット確認
echo "[Test Group 5] レポートフォーマット"
assert_contains "プラグイン監査レポート が含まれる" "$SKILL_FILE" "プラグイン監査レポート\|Plugin Audit Report"
assert_contains "Overall Score が含まれる" "$SKILL_FILE" "Overall Score"
assert_contains "PASS/WARN/FAILステータスが定義されている" "$SKILL_FILE" "PASS\|WARN\|FAIL"
assert_contains "Findings セクションが含まれる" "$SKILL_FILE" "Findings"
assert_contains "改善提案 が含まれる" "$SKILL_FILE" "改善提案\|Recommendation\|必須修正"

echo ""

# 6. サブエージェント活用確認
echo "[Test Group 6] サブエージェント活用"
assert_contains "investigator サブエージェントの記載がある" "$SKILL_FILE" "investigator"
assert_contains "並列実行の記載がある" "$SKILL_FILE" "並列\|parallel"

echo ""

# 7. 関連スキル確認
echo "[Test Group 7] 関連スキル"
assert_contains "plugin-reinstall への参照がある" "$SKILL_FILE" "plugin-reinstall"
assert_contains "user-guide への参照がある" "$SKILL_FILE" "user-guide"

echo ""

# 8. 行数確認（500行以内）
echo "[Test Group 8] トークン効率"
if [ -f "$SKILL_FILE" ]; then
    LINE_COUNT=$(count_lines "$SKILL_FILE")
    assert_true "行数が500行以内 (現在: ${LINE_COUNT}行)" "[ '${LINE_COUNT}' -le 500 ]"
else
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL: 行数確認 (ファイルが存在しない)"
fi
assert_contains "references/ への分離参照がある" "$SKILL_FILE" "references/"

echo ""

# 9. 品質チェック
echo "[Test Group 9] 品質チェック"
assert_not_contains "console.log が残っていない" "$SKILL_FILE" "console\.log"
assert_not_contains "TODO コメントが残っていない" "$SKILL_FILE" "TODO"

echo ""
echo "=== 結果サマリー ==="
echo "実行: $TESTS_RUN / 合格: $TESTS_PASSED / 失敗: $TESTS_FAILED"

if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
else
    echo "All tests passed!"
    exit 0
fi
