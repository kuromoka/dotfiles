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

## 委譲可能なタスクの範囲

Codex agent は **background モードで起動する場合があり、操作が逐次見えない**。途中経過を確認・介入できないため、委譲するタスクは以下に限定する：

- **コード修正**: ファイル編集、リファクタリング、バグ修正、機能追加など
- **git 操作**: commit、branch 作成、merge、rebase など（push などリモートに影響する操作はユーザー確認必須）

以下のような **副作用が大きい・取り返しがつかない・観察が必要** な操作は委譲しない：

- 外部 API 呼び出し・メッセージ送信（Slack、メール、PR コメント等）
- インフラ操作（デプロイ、DB 変更、シークレット操作）
- 対話的な探索・調査（結果を見ながら方針を決める類のタスク）
- 破壊的操作（`rm -rf`、`git reset --hard`、force push 等）

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

### Sonnet 限度切れ時の対応

Claude Code の「あなたの組織の月次使用量限度に達した」エラーは、**モデル別の週間/月間制限に到達** した場合に発生することがある（Sonnet が 100% に達した場合など）。

**対処法**：

1. Claude Code の使用量画面（画面右側の「プラン使用制限」）で各モデルの使用率を確認
2. **Sonnet が 100% に達している場合**、他のモデル（Opus 4.7 / Haiku）はまだ使用可能な場合がある
3. Agent ツールで `model` パラメータを明示指定して、Sonnet 以外を使用：
   ```javascript
   Agent({
     subagent_type: "codex:codex-rescue",
     model: "opus", // Sonnet 代わりに Opus 4.7 を使用
     prompt: "...",
   });
   ```
4. `model` 値: `"opus"` = Opus 4.7 / `"haiku"` = Haiku 4.5

**背景モード実行時も同様** — `run_in_background: true` + `model: "opus"` で指定可能。
