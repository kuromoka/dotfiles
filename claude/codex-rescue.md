# /codex:rescue の運用ルール

ローカルにインストール済みの OpenAI Codex プラグイン（[openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc)、user scope）を活用するためのガイドライン。`codex` CLI のセットアップは `/codex:setup` で確認できる。

## トリガー

ユーザーが以下のシグナルを出したら、`/codex:rescue` 経由で OpenAI Codex に処理を委譲することを **提案する**：

- **usage limit シグナル**: 「もう limit が近い」「rate limit に当たりそう」「このセッションあと残り少ない」など Claude Code の利用上限が近い旨の発言
- **明示的委譲シグナル**: 「codex に任せる」「codex でやって」「rescue で」「codex に頼んで」など

## 振る舞い

1. シグナルを検知したら、まず一度だけ確認する：
   > `/codex:rescue` で Codex に委譲しますか？（要約: <task>）
2. ユーザーが了承したら **`Agent` ツール** で `subagent_type: "codex:codex-rescue"` を呼び、タスク内容を簡潔にまとめてプロンプトに渡す。
3. Codex の出力は **改変せず・要約せず・コメントを足さず**、そのままユーザーに返す（プラグインの強制ルール）。

## 禁止事項

- `Skill(codex:rescue)` は **存在しない**。呼ぶとセッションがハングする（プラグイン `commands/rescue.md` に明記）。
- `Skill(codex:codex-rescue)` も存在しない。
- 確認なしで勝手に発動しない。必ず一度提案を挟む。
- Codex の stdout をパラフレーズ・要約・追記しない。

## 補足

- 書き込み権限は **既定 ON**（`--write`）。読み取り専用にしたい場合のみ Agent プロンプトで明記する。
- 長時間ジョブが見込まれるときは `--background` をユーザーに提案する。
- `codex` CLI 未認証だと判定されたら `/codex:setup` の実行を案内する。
- `--model` はユーザー指定がない場合、デフォルトで `gpt-5.5` を使う（`--model gpt-5.5` を付与）。`spark` と言われたら `gpt-5.3-codex-spark` にマップ。`--effort` はユーザーが明示的に要求した場合のみ付ける。
