#!/usr/bin/env bash
# usage-guard.sh — Claude Code の5時間ブロック使用量を ccusage で近似監視する。
# UserPromptSubmit フックとして呼ばれ、過去最大の「完了ブロック」トークン量に対する
# 現ブロックの比率が閾値(既定95%)を超えたら、additionalContext に「委譲専用モード」
# への切り替え指示を注入する。Claude 本体のトークン消費を抑え、重い作業を codex に
# 丸投げさせるのが目的。
#
# 注意: Claude Code の5時間レート制限%はサーバ側にあり正確な数値は取得できない。
# ここでは ccusage の「過去最大の完了ブロック ≒ プランの実効上限」という近似を使う。
#
# 環境変数で調整可:
#   CLAUDE_USAGE_GUARD_THRESHOLD  発火する使用率% (既定 95)
#   CLAUDE_USAGE_GUARD_FLOOR      maxCompleted がこれ未満なら誤検知防止でスキップ (既定 5000000)
#   CLAUDE_USAGE_GUARD_TTL        ccusage 再実行の最小間隔(秒) (既定 90)
#   CLAUDE_USAGE_GUARD_CACHE      キャッシュファイルのパス (既定 $TMPDIR/claude-usage-guard.cache)
#   CLAUDE_USAGE_GUARD_DISABLE    非空なら常に無効化
set -uo pipefail

[ -n "${CLAUDE_USAGE_GUARD_DISABLE:-}" ] && exit 0

THRESHOLD="${CLAUDE_USAGE_GUARD_THRESHOLD:-95}"
FLOOR="${CLAUDE_USAGE_GUARD_FLOOR:-5000000}"
TTL="${CLAUDE_USAGE_GUARD_TTL:-90}"
CACHE="${CLAUDE_USAGE_GUARD_CACHE:-${TMPDIR:-/tmp}/claude-usage-guard.cache}"

# JSON文字列(引用符込み) を受け取り、UserPromptSubmit の additionalContext として出力する。
# 空文字なら何も出さず終了(=発火なし)。
emit() {
  [ -n "$1" ] || exit 0
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":%s}}\n' "$1"
  exit 0
}

mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

# --- キャッシュ: TTL 内は ccusage を再実行しない ---
if [ -f "$CACHE" ]; then
  now="$(date +%s)"
  age=$(( now - $(mtime "$CACHE") ))
  if [ "$age" -lt "$TTL" ]; then
    emit "$(cat "$CACHE")"
  fi
fi

# --- ccusage 実行 (PATH 優先、なければ npx) ---
if command -v ccusage >/dev/null 2>&1; then
  json="$(ccusage blocks --json 2>/dev/null)" || json=""
else
  json="$(npx -y ccusage@latest blocks --json 2>/dev/null)" || json=""
fi
[ -n "$json" ] || { : > "$CACHE"; exit 0; }

# 現ブロックのトークン量 と 完了ブロックの最大トークン量 を取り出す
read -r active maxc < <(printf '%s' "$json" | jq -r '
  (([.blocks[]|select(.isActive==true)|.totalTokens]|first) // 0) as $a
  | (([.blocks[]|select(.isActive==false and .isGap==false)|.totalTokens]|max) // 0) as $m
  | "\($a) \($m)"' 2>/dev/null)

# 数値ガード
case "${active:-}|${maxc:-}" in
  *[!0-9]*'|'* | *'|'*[!0-9]* | '|' ) : > "$CACHE"; exit 0 ;;
esac
[ "${maxc:-0}" -ge "$FLOOR" ] || { : > "$CACHE"; exit 0; }   # 履歴が薄いうちは黙る
[ "${active:-0}" -gt 0 ]      || { : > "$CACHE"; exit 0; }

pct=$(( active * 100 / maxc ))

if [ "$pct" -lt "$THRESHOLD" ]; then
  : > "$CACHE"   # 空=発火なし
  exit 0
fi

read -r -d '' msg <<EOF || true
[usage-guard] Claude Code の5時間ブロック使用量が過去最大比 ${pct}%（閾値 ${THRESHOLD}%）に到達。
このセッションは残り Claude 予算を温存するため「委譲専用モード」で動くこと:
1. 実装・修正・調査など重い作業は、自分でファイルを読んだり考えたりせず、Bash で codex exec に丸投げして stdout をそのまま中継する。書き込みが要るタスクは -s workspace-write（または --full-auto）、モデルは --model gpt-5.5（codex-rescue.md 準拠）。
2. Claude 本体は「計画の一文 + codex への指示作成 + 結果の中継」だけに徹し、トークンを最小化する。codex の出力は改変・要約・追記しない。
3. 破壊的操作・外部送信(Slack/メール/PR/デプロイ)・シークレット関連は委譲せず、必ずユーザーに確認する。
4. 使用率が閾値を下回れば（このメッセージが出なくなれば）通常運用に戻ってよい。
EOF

ctx="$(jq -n --arg m "$msg" '$m' 2>/dev/null)"
[ -n "$ctx" ] || { : > "$CACHE"; exit 0; }
printf '%s' "$ctx" > "$CACHE"
emit "$ctx"
