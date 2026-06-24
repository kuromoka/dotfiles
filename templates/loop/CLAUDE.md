# <project-name> — CLAUDE.md

## ループ協議（完了条件と自走ルール）

- **完了条件**: `vp check`（フォーマット / lint / 型チェック）と `vp test` が両方とも通過したときのみ「完了」とする。
- 失敗したら原因を直して再実行し、緑になるまで自走で反復する。最大 **5 周**。
- **同一エラーが2回連続したら止めて `fixer`（`.claude/agents/fixer.md`）にエスカレーションする**。
- **トークン / 予算のハード上限を守る**。

## 禁止事項

- **テストの削除・改変でチェックを通すのは禁止**。
- 「passing」にするのは **実際に `vp test` を通してから**。

## 検証ゲート

- `.claude/settings.json` の Stop hook が完了前に `vp check && vp test` を自動実行する。失敗するとターンが終了せず、もう1周になる。

## 進捗の永続化（長時間・複数セッション）

- 機能要件は `feature_list.json`（boolean `passes`）で管理し、各機能は自己検証して通ったときだけ `passes` を true にする。
- 進捗・未解決の問題は外部ファイル（例: `claude-progress.md`）と git 履歴に残す。
