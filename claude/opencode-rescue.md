# opencode 委譲の運用ルール

ローカルにインストール済みの opencode CLI（`~/.opencode/bin/opencode`）へ手動でタスクを委譲するためのガイドライン。codex-rescue と同じ発想を、専用プラグインなしで `opencode run`（ヘッドレス実行）直叩きにより実現する。Claude Code → opencode 方向の公式プラグインは存在しないため、Bash 経由で呼ぶ。

## トリガー

ユーザーが以下のように **明示** したときだけ、opencode への委譲を **一度確認してから** 実行する（自動発動しない）：

- 「opencode に」「opencode で」「opencode に任せて」「opencode で直して」「opencode に頼んで」など、opencode への委譲を明示するシグナル

## 振る舞い

1. シグナルを検知したら、まず一度だけ確認する：
   > opencode に委譲しますか？（要約: <task>）
2. 了承したら **Bash ツール** で `opencode run` を呼ぶ：
   ```sh
   opencode run "<self-contained task>" --dangerously-skip-permissions
   ```
   - モデルはユーザー指定がなければ **opencode の設定済みデフォルトに任せる**（`-m` を付けない）。指定されたら `-m provider/model` を付与する。
   - 長時間ジョブが見込まれるときは Bash の `run_in_background` を提案する。
3. opencode の stdout は **改変せず・要約せず・コメントを足さず**、そのままユーザーに返す。

## 書き込み権限

- **既定 ON**（codex-rescue の「書き込み既定 ON」と揃える）。ヘッドレス実行では権限プロンプトがブロックするため、ファイル編集を伴うタスクは `--dangerously-skip-permissions` を付ける。
- 読み取り専用にしたいときのみ、このフラグを外す。

## 委譲可能なタスクの範囲

codex-rescue と同じ基準。副作用が大きい・取り返しがつかない・観察が必要な操作は委譲しない：

- **委譲可**: コード修正・リファクタリング・バグ修正・機能追加・ローカルな git 操作（push などリモートに影響する操作はユーザー確認必須）
- **委譲しない**: 外部 API 呼び出し・メッセージ送信（Slack・メール・PR コメント等）、インフラ操作（デプロイ・DB 変更・シークレット操作）、対話的な探索・調査（結果を見ながら方針を決める類）、破壊的操作（`rm -rf`・`git reset --hard`・force push 等）

## 禁止事項

- 確認なしで勝手に発動しない。必ず一度提案を挟む。
- opencode の stdout をパラフレーズ・要約・追記しない。

## 補足

- opencode が未認証・プロバイダ未設定だとエラーになる。その場合は `opencode auth`（= `opencode providers`）での設定をユーザーに案内する。
- 出力を機械処理したいときは `--format json`（raw JSON events）を使う。通常の中継は既定の整形出力でよい。

## codex / 下位モデル委譲との使い分け

| シグナル | 委譲先 |
|---|---|
| ユーザーが「codex に」「rescue で」と明示 | codex（[codex-rescue.md](codex-rescue.md)） |
| ユーザーが「opencode に」「opencode で」と明示 | opencode（本ルール） |
| ユーザーが usage limit に近いと発言 | codex（提案あり） |
| 上記以外で、実装量が多く機械的なタスク | general-purpose + 下位モデル（[model-delegate.md](model-delegate.md)・自動・確認なし） |
