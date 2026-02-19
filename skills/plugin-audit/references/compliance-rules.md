# Compliance Rules

Claude Code公式プラグイン仕様に基づくチェックルール一覧。

**重要度の定義:**
- **Critical**: 不合格の場合、そのカテゴリは自動的にFAIL（0点）
- **High**: 主要な品質要件。減点幅が大きい
- **Medium**: 推奨要件。未達成でも軽微な減点
- **Low**: ベストプラクティス。任意対応

---

## 1. plugin.json ルール

| ルールID | チェック内容 | 重要度 | 判定方法 |
|---------|-------------|--------|---------|
| PJ-001 | `.claude-plugin/plugin.json` が存在する | Critical | ファイル存在確認 |
| PJ-002 | `name` フィールドが存在し、ケバブケース | Critical | JSONパース + 正規表現 `^[a-z][a-z0-9-]+$` |
| PJ-003 | `version` がセマンティックバージョニング | High | 正規表現 `^\d+\.\d+\.\d+$` |
| PJ-004 | `description` が存在する | Medium | JSONパース |
| PJ-005 | `author` オブジェクトが存在する | Low | JSONパース |
| PJ-006 | `.claude-plugin/` にマニフェスト以外のファイルがない | High | ディレクトリ内容確認 |

### PJ-001 判定手順

```bash
test -f .claude-plugin/plugin.json && echo "PASS" || echo "FAIL"
```

Criticalのため、不合格時はComplianceカテゴリ全体をFAILとする。

### PJ-002 判定手順

```bash
name=$(jq -r '.name' .claude-plugin/plugin.json)
echo "$name" | grep -qE '^[a-z][a-z0-9-]+$' && echo "PASS" || echo "FAIL"
```

### PJ-006 判定手順

`.claude-plugin/` 内は `plugin.json` のみが想定される。それ以外のファイルが存在する場合はHigh違反。

---

## 2. SKILL.md ルール

| ルールID | チェック内容 | 重要度 | 判定方法 |
|---------|-------------|--------|---------|
| SK-001 | YAMLフロントマターが1行目から開始 | Critical | 先頭3文字が `---` |
| SK-002 | `name` フィールドが存在 | Critical | YAMLパース |
| SK-003 | `description` フィールドが存在 | Critical | YAMLパース |
| SK-004 | descriptionに「何をするか」と「いつ使うか」の両方を含む | High | 文字列パターン確認 |
| SK-005 | Markdown H1見出しが存在 | Medium | `# ` パターン検索 |
| SK-006 | skills/ディレクトリ名がケバブケース | High | 正規表現 `^[a-z][a-z0-9-]+$` |

### SK-001 判定手順

```bash
head -c 3 skills/SKILL_NAME/SKILL.md | grep -q '^---' && echo "PASS" || echo "FAIL"
```

### SK-004 判定指針

descriptionの文字列が以下の両方の要素を含むか確認する:
- 「何をするか」: 動詞を含む行動の記述（例: 「評価する」「生成する」「確認する」）
- 「いつ使うか」: 使用条件の記述（例: 「〜時」「〜の場合」「〜する時に使用」）

例（合格）: `プラグインの状態を評価する時、プラグインの品質チェック時に使用。`
例（不合格）: `プラグインを評価する。`（いつ使うかが不明確）

---

## 3. エージェント定義ルール

| ルールID | チェック内容 | 重要度 | 判定方法 |
|---------|-------------|--------|---------|
| AG-001 | YAMLフロントマターが存在 | Critical | 先頭3文字が `---` |
| AG-002 | `description` フィールドが存在 | Critical | YAMLパース |
| AG-003 | `tools` が定義されている場合、有効なツール名のみ含む | High | 既知ツールリストとの照合 |
| AG-004 | `model` が有効値（sonnet/opus/haiku） | Medium | 値の検証 |
| AG-005 | `permission` が有効値（plan/acceptEdits/default/bypassPermissions） | Medium | 値の検証 |

### AG-003 有効なツール名一覧

```
Bash, Read, Write, Edit, Glob, Grep, Task, WebFetch, WebSearch,
TodoRead, TodoWrite, NotebookRead, NotebookEdit
```

上記以外のツール名が `tools` フィールドに含まれる場合はHigh違反。

### AG-004 有効なmodel値

- `sonnet`（claude-sonnet系）
- `opus`（claude-opus系）
- `haiku`（claude-haiku系）
- フルモデルID（例: `claude-sonnet-4-5`）も許容

### AG-005 有効なpermission値

- `plan`: 計画モード（実行確認が必要）
- `acceptEdits`: ファイル編集を自動承認
- `default`: デフォルト権限
- `bypassPermissions`: 全操作を自動承認（危険）

---

## 4. hooks.json ルール

| ルールID | チェック内容 | 重要度 | 判定方法 |
|---------|-------------|--------|---------|
| HK-001 | 有効なJSON | Critical | `jq empty` |
| HK-002 | `hooks` キーが存在 | Critical | JSONパース |
| HK-003 | イベント名が有効（PreToolUse/PostToolUse/SessionStart等） | High | 既知イベントリストとの照合 |
| HK-004 | 各フックに `type: "command"` | High | JSONパース |
| HK-005 | `command` で参照されるスクリプトが存在 | Critical | ファイル存在確認 |
| HK-006 | `timeout` が設定されている | Medium | JSONパース |
| HK-007 | plugin.jsonの `hooks` フィールドに `hooks/hooks.json` が重複登録されていない | High | plugin.json確認 |

### HK-001 判定手順

```bash
jq empty hooks/hooks.json 2>/dev/null && echo "PASS" || echo "FAIL"
```

### HK-003 有効なイベント名一覧

```
PreToolUse
PostToolUse
SessionStart
SessionEnd
Notification
Stop
```

上記以外のイベント名が含まれる場合はHigh違反。

### HK-005 判定手順

```bash
# hooks.json内のcommandフィールドで参照されるスクリプトの存在確認
jq -r '.hooks[][][].command' hooks/hooks.json | while read cmd; do
  script=$(echo "$cmd" | awk '{print $1}')
  test -f "$script" || echo "FAIL: $script が存在しない"
done
```

### HK-007 補足

`plugin.json` の `hooks` フィールドには `hooks/hooks.json` を登録するが、フックスクリプト自体が `hooks.json` を再度読み込む二重登録は禁止。

---

## 5. コマンド定義ルール

| ルールID | チェック内容 | 重要度 | 判定方法 |
|---------|-------------|--------|---------|
| CM-001 | YAMLフロントマターが存在 | Critical | 先頭3文字が `---` |
| CM-002 | `description` が定義されている | Medium | YAMLパース |
| CM-003 | ファイル名がケバブケース.md | Medium | 正規表現 `^[a-z][a-z0-9-]+\.md$` |

### CM-001 判定手順

```bash
for f in commands/*.md; do
  head -c 3 "$f" | grep -q '^---' || echo "FAIL: $f にフロントマターがない"
done
```

---

## 6. セキュリティルール

| ルールID | チェック内容 | 重要度 | 判定方法 |
|---------|-------------|--------|---------|
| SEC-001 | フックスクリプトで変数が `"$VAR"` でクォートされている | High | シェル解析 |
| SEC-002 | `CLAUDE_PLUGIN_ROOT` がソースパス解決に使われていない | Critical | grepで検出 |
| SEC-003 | `.env` ファイルへの参照がない | High | grepで検出 |
| SEC-004 | reinstall時の自己参照防止ガードが存在 | Medium | コード確認 |
| SEC-005 | フックスクリプトに `set -euo pipefail` または適切なエラーハンドリング | Medium | 先頭行確認 |

### SEC-001 判定手順

```bash
# クォートなし変数展開のパターンを検出（false positiveに注意）
grep -n '\$[A-Z_][A-Z0-9_]*[^"]' hooks/**/*.sh | grep -v '"'
```

クォートなし変数（例: `$VAR`）が検出された場合はHigh違反。
ただし `$(command)` 形式のコマンド置換は対象外。

### SEC-002 判定手順

```bash
# CLAUDE_PLUGIN_ROOTをパス解決に使用しているコードを検出
grep -rn 'CLAUDE_PLUGIN_ROOT' hooks/ scripts/ | grep -v '#'
```

`CLAUDE_PLUGIN_ROOT` はキャッシュパスを返すため、ソースパス解決には使用禁止。
代わりに `~/.claude/plugins/local/{name}` のシンボリックリンクから解決すること。

### SEC-003 判定手順

```bash
grep -rn '\.env' hooks/ scripts/ | grep -v '\.env\.'
```

`.env` ファイルへの直接参照はシークレット漏洩リスクがある。

### SEC-004 判定内容

`reinstall` 相当のスクリプトで、SOURCE_DIRがキャッシュパス内（`~/.claude/cache/` 等）の場合に処理を中断するガードが存在するか確認する。

### SEC-005 判定手順

```bash
for sh in hooks/**/*.sh scripts/**/*.sh; do
  head -5 "$sh" | grep -qE 'set -[a-z]*e[a-z]*' || echo "WARN: $sh にset -eがない"
done
```

---

## 判定の集計方針

### Criticalルール不合格時の扱い

Criticalルールが1件でも不合格の場合、そのルールが属するカテゴリのスコアは **0点** とする。

| カテゴリ | 関連するCriticalルール |
|---------|----------------------|
| Compliance | PJ-001, SK-001〜003, AG-001〜002, HK-001〜002, HK-005, CM-001 |
| Security | SEC-002 |

### 証拠の記録形式

各チェック結果には以下の形式で証拠を記録すること:

```
ルールID: PASS/FAIL
証拠: {ファイルパス}:{行番号}
コマンド: {実行したコマンド}
結果: {コマンド出力}
```

証拠なしの評価は0点として扱う（推測禁止）。
