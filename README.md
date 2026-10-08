# dotfiles

macOS 用の設定ファイル一式。macOS では `install.sh` を使って配置する。配置先は `~/projects/dotfiles` に統一する。Windows 用には AutoHotkey の入力切り替え設定だけを残す。

## セットアップ

### macOS

```sh
mkdir -p ~/projects &&
git clone https://github.com/kuromoka/dotfiles.git ~/projects/dotfiles &&
cd ~/projects/dotfiles &&
bash install.sh
```

`install.sh` は以下を行う：

- Homebrew と zsh-autosuggestions を導入
- Rust / pnpm / Vite+ のインストール（未導入の場合のみ）
- [`natural-japanese`](https://github.com/coji/natural-japanese)スキルを取得し、Claude Code / Codexへインストール
- `kuromoka-writing`スキルをClaude Code / Codex / Antigravity CLIへ配置
- ほとんどの設定ファイルをホームディレクトリへシンボリックリンク（異なる既存ファイルは連番付き `.bak` にバックアップ）
- Ghostty と Karabiner の設定を配置
- Codexのカスタムエージェントを`~/.codex/agents/`へ通常ファイルとして同期（既存ファイルは連番付き `.bak` にバックアップ）
- Git の補完・プロンプトスクリプトを `~/.zsh/` にダウンロード

必要なツールは別途導入する。Ghostty・Yazi・Herdr・Karabiner・Claude Code・Codex などのアプリ本体は、このスクリプトでは導入しない。ログインシェルの変更は行わない。

Claude の配置先は `CLAUDE_CONFIG_DIR`、Codex は `CODEX_HOME` が設定されていればその値を使う。既定の配置先は、それぞれ `~/.claude` と `~/.codex`。[Claude の設定場所](https://code.claude.com/docs/en/settings)、[Codex の環境変数](https://learn.chatgpt.com/docs/config-file/environment-variables)

macOS でホーム外の配置先を指定する場合、親ディレクトリに独自のシンボリックリンクがあれば実パスを指定する。意図しないリンク先の変更を避けるため、そのような配置先は拒否する。

### Windows

Git for Windows と AutoHotkey v2 を導入してから、PowerShell で専用スクリプトを実行する。REALFORCE for Mac の Command キー単独押しで Microsoft IME を切り替える設定を、スタートアップに登録する。

| 操作 | 動作 |
|---|---|
| 左 Command を単独で短く押す | IME オフ（英数入力） |
| 右 Command を単独で短く押す | IME オン（日本語入力） |
| Command と別のキーを同時に押す | Windows キーのショートカット（例：Command + E でエクスプローラー） |

単独押しは500ms以内で、ほかのキーを押したり、マウスのボタン・ホイールを操作したりしない場合に判定する。左右Commandの単独押しではスタートメニューを開かない。スタートメニューは Ctrl + Esc で開ける。

左Commandが `LWin`、右Commandが `RWin` として認識される配置に対応する。キーボードのモードによって右Commandが `AppsKey` として認識される場合もIMEオンに対応するが、その場合の右CommandはIME切り替え専用になる。

インストーラーはスタートアップへの登録だけを行い、AutoHotkeyをその場では起動しない。次回Windowsログイン時に自動起動する。すぐに使う場合は、エクスプローラーから `autohotkey/realforce-ime.ahk` をダブルクリックして起動する。

```powershell
$projects = Join-Path $HOME "projects"
New-Item -ItemType Directory -Path $projects -Force -ErrorAction Stop | Out-Null
$dotfiles = Join-Path $projects "dotfiles"
git clone https://github.com/kuromoka/dotfiles.git $dotfiles
if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
Set-Location $dotfiles -ErrorAction Stop
powershell -NoProfile -ExecutionPolicy Bypass -File .\autohotkey\install.ps1
```

既に `~/projects/dotfiles` に取得済みの場合は、取得手順を省略して専用スクリプトを実行する。PowerShell の `~` は `$HOME` を指す。AutoHotkey の実行ファイルを自動検出できない場合は、`-AutoHotkeyPath <path-to-AutoHotkey.exe>` を指定する。

## 更新

macOS の各マシン上でリポジトリを `pull --ff-only` し、`install.sh` を再実行する。更新内容が分岐している場合は pull を停止するので、先に差分を確認する。

macOS：

```sh
cd ~/projects/dotfiles && git pull --ff-only && bash install.sh
```

Windows で AutoHotkey 設定を更新する場合は、PowerShell で次を実行する。

```powershell
Set-Location (Join-Path $HOME "projects/dotfiles") -ErrorAction Stop
git pull --ff-only
if ($LASTEXITCODE -eq 0) {
    powershell -NoProfile -ExecutionPolicy Bypass -File .\autohotkey\install.ps1
}
```

実行中のAutoHotkeyへ更新を反映するには、Windows画面の通知領域にあるAutoHotkeyアイコンから `Reload Script` を選ぶか、エクスプローラーから `autohotkey/realforce-ime.ahk` を再度起動する。次回ログイン時にも更新後の設定が読み込まれる。

## 構成

| パス | 内容 |
|---|---|
| `AGENTS.md` | このリポジトリ固有のClaude Code / Codex共通ルール |
| `CLAUDE.md` | `AGENTS.md`へのClaude Code互換symlink |
| `install.sh` | macOS の依存ツール導入・設定配置 |
| `scripts/install-common.sh` | macOS の導入・配置処理 |
| `.zshrc` / `.zshenv` / `.zprofile` | zsh の設定 |
| `.gitconfig` / `.gitignore_global` | Git の設定 |
| `.vimrc` | Vim の設定 |
| `ghostty/` | Ghostty（ターミナル）の設定 |
| `karabiner/` | Karabiner-Elements（キーリマップ）の設定 |
| `autohotkey/` | Windows 用の AutoHotkey 設定。左Command単押しでIMEオフ、右Command単押しでIMEオン。専用インストーラーでスタートアップに登録 |
| `yazi/` | yazi（ファイラー）の設定 |
| `herdr/` | herdr（エージェント多重化ターミナル）の設定 |
| `claude/` | Claude Code の設定（下記） |
| `codex/` | Codex CLI の設定（下記） |

### claude/

Claude Code / Codex 用の設定。macOS にリンクで配置する（`AGENTS.md` は Codex にも共有）。

| ファイル | 内容 |
|---|---|
| `settings.json` | 本体設定（permission mode、deny ルール、プラグイン等） |
| `statusline-command.sh` | ステータスライン表示スクリプト |
| `AGENTS.md` | 汎用エージェント設定（Claude Code / Codex 共通）。git/GitHub 操作・新規プロジェクトのデフォルト技術スタック・ユーザー名義の文章で使う文体スキル。Claude / Codex の両方へ配置 |
| `CLAUDE.md` | Claude 専用のグローバル指示（`AGENTS.md` と下記の各ルールを import） |
| `codex-rescue.md` | OpenAI Codex プラグインへの委譲ルール |
| `model-delegate.md` | 下位モデルへの実装委譲ルール（Fable → Opus、Opus → Sonnet） |
| `skills/reload-rules/` | CLAUDE.md を再読み込みするスキル |
| `skills/kuromoka-writing/` | 本人の希望と過去記事の傾向を絞り込み、本人らしい日本語で書く共通スキル。Claude Code / Codex / Antigravity CLIで共有する。`references/`の分析資料はスキルの見直し時だけ使う。`natural-japanese`はmacOSのインストーラーで外部から導入 |

> **Note**: `settings.json` の SessionStart フックが呼ぶ `~/.claude/hooks/herdr-agent-state.sh` は、`herdr integration install claude` で自動生成・管理されるスクリプト（herdr の再インストール時に上書きされる）。このリポジトリでは管理しないため、herdr を使う環境では別途上記コマンドで導入する。

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

## インストール時の検証

`install.sh` は、完了前に配置した設定を自動で検証する。ファイルの内容・リンク先、Codex エージェントが通常ファイルであること、既存の未管理ファイルが保持されていることを確認する。不一致があればエラーで終了し、対象のパスを表示する。別途検証コマンドを実行する必要はない。

## 機密情報の扱い

APIトークン・パスワード・個人情報を、設定ファイルやドキュメントに含めない。

マシン固有のシェル設定は `~/.zshrc.local`、Git の名前・メールアドレス等は `~/.gitconfig.local` に置く。共有の `.zshrc` と `.gitconfig` がそれぞれ読み込む。これらのファイルや秘密情報を、このリポジトリにコミットしない。
