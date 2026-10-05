# dotfiles

macOS と Windows 用の設定ファイル一式。`install.sh` が macOS の設定ファイル配置と依存ツールのインストールを行う。

## セットアップ

```sh
git clone https://github.com/kuromoka/dotfiles.git
cd dotfiles
bash install.sh
```

`install.sh` は以下を行う：

- Homebrew / zsh-autosuggestions / Rust / pnpm / Vite+ のインストール（未導入の場合のみ）
- [`natural-japanese`](https://github.com/coji/natural-japanese)スキルを取得し、Claude Code / Codexへインストール
- `kuromoka-writing`スキルをClaude Code / Codex / Antigravity CLIへ配置
- ほとんどの設定ファイルをホームディレクトリへシンボリックリンク（既存ファイルは `.bak` にバックアップ）
- Codexのカスタムエージェントを`~/.codex/agents/`へ通常ファイルとして同期（既存ファイルは連番付き `.bak` にバックアップ）
- Git の補完・プロンプトスクリプトを `~/.zsh/` にダウンロード

## 構成

| パス | 内容 |
|---|---|
| `AGENTS.md` | このリポジトリ固有のClaude Code / Codex共通ルール |
| `CLAUDE.md` | `AGENTS.md`へのClaude Code互換symlink |
| `.zshrc` / `.zshenv` / `.zprofile` | zsh の設定 |
| `.gitconfig` / `.gitignore_global` | Git の設定 |
| `.vimrc` | Vim の設定 |
| `ghostty/` | Ghostty（ターミナル）の設定 |
| `karabiner/` | Karabiner-Elements（キーリマップ）の設定 |
| `autohotkey/` | Windows 用の AutoHotkey 設定。REALFORCE for Mac の Command キー単独押しで Microsoft IME を切り替える |
| `yazi/` | yazi（ファイラー）の設定 |
| `herdr/` | herdr（エージェント多重化ターミナル）の設定 |
| `claude/` | Claude Code の設定（下記） |
| `codex/` | Codex CLI の設定（下記） |

### claude/

Claude Code / Codex 用の設定。主に `~/.claude/` 以下にリンクされる（`AGENTS.md` は `~/.codex/` にも共有）。

| ファイル | 内容 |
|---|---|
| `settings.json` | 本体設定（permission mode、deny ルール、プラグイン等） |
| `statusline-command.sh` | ステータスライン表示スクリプト |
| `AGENTS.md` | 汎用エージェント設定（Claude Code / Codex 共通）。git/GitHub 操作・新規プロジェクトのデフォルト技術スタック・ユーザー名義の文章で使う文体スキル。`~/.claude/AGENTS.md` と `~/.codex/AGENTS.md` の両方にリンクされる |
| `CLAUDE.md` | Claude 専用のグローバル指示（`AGENTS.md` と下記の各ルールを import） |
| `AGENTS.local.md` | マシン固有のローカル上書き（git 管理外）。`~/.claude/AGENTS.local.md` / `~/.codex/AGENTS.local.md` にリンク。Claude は CLAUDE.md の `@AGENTS.local.md` ネイティブ import、Codex は `AGENTS.md` 内の自然言語指示で読み込む |
| `codex-rescue.md` | OpenAI Codex プラグインへの委譲ルール |
| `model-delegate.md` | 下位モデルへの実装委譲ルール（Fable → Opus、Opus → Sonnet） |
| `skills/reload-rules/` | CLAUDE.md を再読み込みするスキル |
| `skills/kuromoka-writing/` | 本人の希望と過去記事の傾向を絞り込み、本人らしい日本語で書く共通スキル。Claude Code / Codex / Antigravity CLIで共有する。`references/`の分析資料はスキルの見直し時だけ使う。`natural-japanese`は`install.sh`で外部から導入 |

> **Note**: `settings.json` の SessionStart フックが呼ぶ `~/.claude/hooks/herdr-agent-state.sh` は、`herdr integration install claude` で自動生成・管理されるスクリプト（herdr の再インストール時に上書きされる）。このリポジトリでは管理しないため、herdr を使う環境では別途上記コマンドで導入する。

ローカル上書きの仕組み（ハイブリッド）:

- **Claude Code**: `CLAUDE.md` が `@AGENTS.local.md` をネイティブ import（プロンプトに確実に展開）。
- **Codex**: `@import` 非対応のため、共有 `AGENTS.md` に「Codex の場合は応答前に必ず `~/.codex/AGENTS.local.md` を読んで従え」と自然言語で指示し、エージェントがシェルで読み込む。
- `AGENTS.local.md` は `.gitignore`（`*.local.md`）で除外。`install.sh` は無ければ雛形を自動生成する。

### codex/

Codex CLI 用の設定。カスタムエージェントの TOML は `~/.codex/agents/` へ通常ファイルとして同期される。

| パス | 内容 |
|---|---|
| `agents/implementer.toml` | 機械的な実装用エージェントプロファイル（gpt-6.1-sol / medium effort）。一括編集・スキャフォールド・マイグレーション等 |
| `agents/researcher.toml` | 読み込み主体の調査用エージェントプロファイル（gpt-6.1-sol / low effort / read-only） |
| `sync-agents.sh` | `agents/*.toml`を`~/.codex/agents/`へ通常ファイルとして同期 |

実装と調査を目的別に委譲するためのプロファイル。Claude Code の `model-delegate.md` と同じ思想を Codex のプロファイル方式で実現する。

Codexのカスタムエージェントはsymlinkにせず、次のコマンドで同期する。プロファイルを変更した場合も再実行する。

```sh
./codex/sync-agents.sh
```

## Windows: REALFORCE for Mac の IME 切り替え

`autohotkey/realforce-ime.ahk` は、英語配列の REALFORCE for Mac R2 テンキーレスを Windows モード（`Fn + End`）で使うための設定。日本語 Microsoft IME を有効にし、キーボード レイアウトは US にする。

- 左 Command（`LWin`）を単独で 500 ms 以内に離すと IME をオフにする（英数）。Windows ショートカットはそのまま使える。
- 右 Command（`AppsKey`）を単独で 500 ms 以内に離すと IME をオンにする（かな）。このキーは IME 専用になるため、コンテキストメニューは `Shift + F10` を使う。
- 別のキーやマウスのクリック・スクロールとの組み合わせ、長押しでは IME を切り替えない。Ctrl への再割り当ては行わない。

[AutoHotkey v2](https://www.autohotkey.com/) をインストールしてから、Windows の PowerShell でリポジトリのルートから次を実行する。現在のセッションだけで試す場合は `realforce-ime.ahk` を直接起動する。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\autohotkey\install.ps1
```

このコマンドはユーザーごとのスタートアップにショートカットを作成する。自動起動をやめるには、そのスタートアップの `REALFORCE IME.lnk` を削除する。実行中のスクリプトは通知領域の AutoHotkey アイコンから `Exit` で停止できる。

動作確認では、左 Command の単独押しを繰り返して IME がオフになり、右 Command の単独押しでオンになることを確認する。`Win + E`、`Win + R`、`Win + Space`、マウスのクリック・スクロールとの同時操作、ほかのキーとの組み合わせでは IME が切り替わらないことも確認する。

仮想キーは [Microsoft の一覧](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes)、Windows モードのキー配置は [REALFORCE のマニュアル](https://www.realforce.co.jp/en/products/discontinued/R2TL-USVM-WH/REALFORCE_TKL_for_Mac_US_Manual.pdf)を参照している。Windows 実機での動作確認は macOS 上では行っていない。

## 機密情報の扱い

シークレットや個人情報はリポジトリに含めず、ローカル専用ファイルに分離する：

- `~/.zshrc.local` — API トークン等の環境変数（`.zshrc` から読み込まれる）
- `~/.gitconfig.local` — Git の `name` / `email`（`.gitconfig` から include される）
