---
description: プラグインの状態を5カテゴリで評価しスコア付きレポートを生成
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Task
  - Write
---

`fractal-dev-workflow:plugin-audit` スキルを呼び出し、スキルの手順に厳密に従って実行すること。

$ARGUMENTS があればオプションとして渡すこと（例: 特定カテゴリのみ評価）。

**重要な出力要件:**
- レポートは `docs/audits/YYYY-MM-DD.md`（実行日の日付）に Write ツールで書き出すこと
- レポートは全て日本語で記述すること
- マーメイド図を3種類含めること（xychart-beta 棒グラフ、pie 円グラフ、flowchart TD フローチャート）

Task ツールを使用して `fractal-dev-workflow:plugin-audit` を上記の引数と要件で起動すること。
