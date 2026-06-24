# ループテンプレート（デフォルトスタック: pnpm / TypeScript / React / Vite+）

デフォルトスタックのプロジェクトを「自走ループ対応」にするための雛形。`verify.sh` のようなラッパーは使わず、Vite+ のコマンド（`vp check` / `vp test`）を hook から直接呼ぶ。

`loop/` はプロジェクトのレイアウトをミラーしているので、**中身をプロジェクトルートにコピーするだけ**で配置が完了する。

## 取得・配置（gh）

新規プロジェクトのルートで実行:

```sh
tmp=$(mktemp -d) && gh repo clone kuromoka/dotfiles "$tmp" -- --depth 1 -q && cp -R "$tmp/claude/templates/loop/." . && rm -rf "$tmp"
```

展開されるもの:

| ファイル | 配置先 |
|---|---|
| `CLAUDE.md` | プロジェクトルート（既存があれば「ループ協議」節を統合） |
| `feature_list.json` | プロジェクトルート |
| `.claude/settings.json` | `.claude/settings.json` |
| `.claude/agents/fixer.md` | `.claude/agents/fixer.md` |

## 前提

- `gh` CLI が使えること（公開リポジトリなので認証は不要）。
- Vite+（`vp`）が使えること。`vp check` = フォーマット / lint / 型チェック一括、`vp test` = テスト。

## 仕組み

- **検証ゲート**: `.claude/settings.json` の Stop hook が完了前に `vp check && vp test` を自動実行。失敗するとターンが終了せず、もう1周になる（Claude Code は8連続ブロックで override）。
- **逐次チェック**: PostToolUse(Edit|Write) で `vp check` を走らせ、型/lint エラーを即座に戻す。
- **行き詰まり打破**: 連続失敗時は `fixer` エージェントへ。
- **早すぎる完了の防止**: `feature_list.json` の `passes` を、実際に検証が通ってから true にする。

## 調整

- PostToolUse の `vp check` が毎編集で重い場合は、その hook を外して Stop ゲートだけ残す。
- Stop の `timeout` はテスト時間に合わせて調整する。
