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

## 結果が宙に浮く問題（必ず対処する）

**`codex-rescue` サブエージェント自身は、起動したジョブの状態確認・出力取得の権限を持たない。**
そのため「実行中か終了済みか分からない」と報告して停止し、**実際には完了して結果が書かれているのに
誰も取りに行かない**状態になる（2026-07-28 に実際に発生）。**状態確認をサブエージェントに依頼しても
答えられないので無駄**——メインモデルが自分で読む。

読む場所はプラグインのバージョンで変わる。**両方を知っておき、存在する方を読む**:

### 方式A: タスクID方式（現行。サブエージェントが `task-xxxx-yyyy` を返す）

```bash
D=~/.claude/plugins/data/codex-openai-codex/state/<project>-<hash>/jobs
ls -t $D/*.json | head -1                    # 最新のジョブ
python3 -c "import json;d=json.load(open('$D/<taskid>.json'));print(d['status'])"
```

- `status` が `running` / `completed` で分かる。**完了していれば同JSONの `result.rawOutput` に
  Codex の最終出力が入っている**（`rendered` にも入ることがある）。
- `<taskid>.log` に実行ログ。
- `<project>-<hash>` は `ls ~/.claude/plugins/data/codex-openai-codex/state/` で確認する。

### 方式B: Bash バックグラウンド方式（旧。600秒でタイムアウトして移行する）

- サブエージェントの報告に `/private/tmp/.../tasks/<id>.output` の形でパスが載る。
- **メインモデルが直接 `cat` する**。これは Bash background task の出力であって
  サブエージェントの JSONL トランスクリプトではないので、読んで問題ない。
- ファイル末尾、`[codex] Turn completed.` の後に最終出力が入っている。

### 共通

- まだ走っているなら `until` ループか `Monitor` で完了を待つ（方式Aなら status を、
  方式Bならプロセスとファイル更新時刻を見る）。
- **予防**: 長時間化が見込まれるタスクは最初から Agent の `run_in_background: true` で投げ、
  上記の手順で結果を取りに行く前提で動く。

## 長時間ジョブの投げ方

10分を超えることが見込まれるタスクは、以下に従う。

### 禁止

- **`--background` を使わない**（プロンプト本文に書くのも、`task` に転送するのも不可）。
  スクリプト側で解釈されるだけで、実際にプロセスを切り離すのは
  Claude Code の `Bash(..., run_in_background: true)` の側。
- **`--fresh` を付けずに投げない**。直前のスレッドが残っていると resume 扱いになり
  （ジョブの title が `Codex Resume`）、そのスレッドが死んでいると起動直後に `failed`
  になる（`pid: null`、ログはエラー本文なしの数行だけ）。
- **サブエージェント経由で投げない**。サブエージェント側の Bash が10分で打ち切られ、
  Codex の子プロセスも一緒に死ぬ。

### 手順

companion スクリプトを **Bash ツールの `run_in_background: true`** で直接叩く:

```bash
cat <prompt file> | node \
  "$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs" \
  task --fresh --model gpt-5.6-sol > <output file> 2>&1
```

- **プロンプトは stdin でパイプする**（`task` は prompt / prompt file / piped stdin /
  `--resume-last` のいずれかを受け付ける）。
- 読み取り専用にしたいときは `--write` を付けず、**プロンプト本文にも編集禁止を明記する**。
- 完走すれば stdout に最終報告が出るので、出力ファイルを読む。

### `task` の引数

```
task [--background] [--write] [--resume-last|--resume|--fresh]
     [--model <model|spark>] [--effort <none|minimal|low|medium|high|xhigh>] [prompt]
```

`--help` は **タスク本文として Codex に渡ってしまう**。引数を確認するときは
`scripts/codex-companion.mjs` の usage 行を直接読む。

## 出力の検証について（改変禁止と混同しない）

「Codex の stdout を改変・要約しない」は**そのまま提示する**という意味であって、
**内容を検証してはいけないという意味ではない**。Codex は、対象ドメインのルール・仕様を
誤解したまま、もっともらしい提案を返すことがある（そのドメインの制約上そもそも取り得ない
選択肢を「こうすべきだった」と指摘する、実在しない API・データを前提に語る、など）。

- **出力はそのまま提示する**（要約・パラフレーズしない）。
- そのうえで、**検証できる主張は検証し、誤りがあれば別途はっきり指摘する**。
- 特に「ルール上可能か」「そのデータが実在するか」は機械的に確かめられることが多い。

## 補足

- 書き込み権限は **既定 ON**（`--write`）。読み取り専用にしたい場合のみ Agent プロンプトで明記する。
- **`--background` を使わない**（前述「長時間ジョブの投げ方」参照）。
- `codex` CLI 未認証だと判定されたら `/codex:setup` の実行を案内する。
- `--model` はユーザー指定がない場合、デフォルトで `gpt-5.6-sol` を使う（`--model gpt-5.6-sol` を付与）。`--effort` はユーザーが明示的に要求した場合のみ付ける。
- モデル指定は GPT-5.6 ファミリーから選ぶ。`gpt-5.6-sol`（フラッグシップ / 品質優先）、`gpt-5.6-terra`（バランス）、`gpt-5.6-luna`（高スループット・低レイテンシ）。エイリアス `gpt-5.6` は sol にルーティングされる。
- プラグイン側のエイリアス `spark`（`gpt-5.3-codex-spark`）は使わない。現行 CLI のモデル一覧に無い。

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
