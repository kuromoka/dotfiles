---
description: グローバルおよびプロジェクトの CLAUDE.md を再読み込みして最新の指示に従う
disable-model-invocation: true
---

以下のファイルを Read ツールで読み込み、内容を最新の指示として優先してください。
古い指示と矛盾する場合は読み込んだ最新版が常に優先されます。

1. `~/.claude/CLAUDE.md` — グローバル設定
2. 上記の中で `@xxx.md` 構文で import されているファイル全て
   （`@codex-rescue.md`、`@sonnet-delegate.md` 等）も再帰的に Read
3. プロジェクトルートの `CLAUDE.md`（存在すれば）
4. プロジェクトの `.claude/CLAUDE.md`（存在すれば）

読み終えたら、変更点があれば一行で要約してから次の作業に戻ってください。
