# dotfiles

macOS・Ubuntu・Windows 用の設定ファイル一式。macOS は `install.sh`、Ubuntu は `install-ubuntu.sh`、Windows は `install.ps1` で配置する。Windows の共有対象は Git・Claude Code・Codex の設定に絞る。

## セットアップ

### macOS

```sh
git clone https://github.com/kuromoka/dotfiles.git
cd dotfiles
bash install.sh
```

### Ubuntu

```sh
git clone https://github.com/kuromoka/dotfiles.git
cd dotfiles
bash install-ubuntu.sh
```

macOS / Ubuntu のインストーラーは以下を行う：

- macOS は Homebrew と zsh-autosuggestions、Ubuntu は apt で基本ツールと zsh-autosuggestions を導入
- Rust / pnpm / Vite+ のインストール（未導入の場合のみ）
- [`natural-japanese`](https://github.com/coji/natural-japanese)スキルを取得し、Claude Code / Codexへインストール
- `kuromoka-writing`スキルをClaude Code / Codex / Antigravity CLIへ配置
- ほとんどの設定ファイルをホームディレクトリへシンボリックリンク（異なる既存ファイルは連番付き `.bak` にバックアップ）
- Karabiner は macOS のみ配置。Ubuntu の Ghostty 設定では macOS 専用項目を除外
- Codexのカスタムエージェントを`~/.codex/agents/`へ通常ファイルとして同期（既存ファイルは連番付き `.bak` にバックアップ）
- Git の補完・プロンプトスクリプトを `~/.zsh/` にダウンロード

Ubuntu では Git・zsh・Vim・jq・C/C++ のビルド環境も導入する。macOS では必要なツールを別途導入する。Ghostty・Yazi・Herdr・Karabiner・Claude Code・Codex などのアプリ本体は、このスクリプトでは導入しない。Ubuntu では apt 実行時に管理者権限が必要になる。ログインシェルの変更は行わない。

### Windows

Git for Windows・Claude Code・Codex を導入してから、PowerShell で実行する。

```powershell
git clone https://github.com/kuromoka/dotfiles.git
cd dotfiles
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

`install.ps1` は Git 設定、Claude Code のルール・スキル・設定、Codex のルール・スキル・エージェントをコピーする。異なる既存ファイルは連番付き `.bak` に退避し、同じ内容なら変更しない。管理者権限やシンボリックリンクの作成権限は不要。リポジトリを更新した後は再実行して反映する。

Claude の設定は共通の `claude/settings.json` から生成する。Windows では Herdr 用のフックを除外する。Git Bash と jq が使える場合はステータスラインを有効にし、使えない場合は無効にして案内を表示する。jq を追加した後は再実行する。

ソフト本体、プラグイン、外部の `natural-japanese` スキルの導入やログインは行わない。AutoHotkey の入力切り替えは `autohotkey/install.ps1` で別途設定する。

Claude の配置先は `CLAUDE_CONFIG_DIR`、Codex は `CODEX_HOME` が設定されていればその値を使う。既定の配置先は、それぞれ `~/.claude` と `~/.codex`。[Claude の設定場所](https://code.claude.com/docs/en/settings)、[Codex の環境変数](https://learn.chatgpt.com/docs/config-file/environment-variables)

macOS / Ubuntu でホーム外の配置先を指定する場合、親ディレクトリに独自のシンボリックリンクがあれば実パスを指定する。意図しないリンク先の変更を避けるため、そのような配置先は拒否する。

## 構成

| パス | 内容 |
|---|---|
| `AGENTS.md` | このリポジトリ固有のClaude Code / Codex共通ルール |
| `CLAUDE.md` | `AGENTS.md`へのClaude Code互換symlink |
| `install.sh` | macOS の依存ツール導入・設定配置 |
| `install-ubuntu.sh` | Ubuntu の依存ツール導入・設定配置 |
| `install.ps1` | Windows の Git・Claude Code・Codex 設定配置 |
| `scripts/install-common.sh` | macOS / Ubuntu の共通導入・配置処理 |
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

Claude Code / Codex 用の設定。macOS / Ubuntu はリンク、Windows はコピーで配置する（`AGENTS.md` は Codex にも共有）。

| ファイル | 内容 |
|---|---|
| `settings.json` | 本体設定（permission mode、deny ルール、プラグイン等） |
| `statusline-command.sh` | ステータスライン表示スクリプト |
| `AGENTS.md` | 汎用エージェント設定（Claude Code / Codex 共通）。git/GitHub 操作・新規プロジェクトのデフォルト技術スタック・ユーザー名義の文章で使う文体スキル。Claude / Codex の両方へ配置 |
| `CLAUDE.md` | Claude 専用のグローバル指示（`AGENTS.md` と下記の各ルールを import） |
| `codex-rescue.md` | OpenAI Codex プラグインへの委譲ルール |
| `model-delegate.md` | 下位モデルへの実装委譲ルール（Fable → Opus、Opus → Sonnet） |
| `skills/reload-rules/` | CLAUDE.md を再読み込みするスキル |
| `skills/kuromoka-writing/` | 本人の希望と過去記事の傾向を絞り込み、本人らしい日本語で書く共通スキル。Claude Code / Codex / Antigravity CLIで共有する。`references/`の分析資料はスキルの見直し時だけ使う。`natural-japanese`はmacOS / Ubuntuのインストーラーで外部から導入 |

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

Windows ではルートの `install.ps1` を再実行して同期する。

## インストール時の検証

各インストーラーは、完了前に配置した設定を自動で検証する。ファイルの内容・リンク先、Codex エージェントが通常ファイルであること、既存の未管理ファイルが保持されていることを確認する。不一致があればエラーで終了し、対象のパスを表示する。別途検証コマンドを実行する必要はない。

## 機密情報の扱い

APIトークン・パスワード・個人情報を、設定ファイルやドキュメントに含めない。
