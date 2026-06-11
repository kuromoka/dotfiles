# dotfiles

macOS 用の設定ファイル一式。`install.sh` がシンボリックリンクの作成と依存ツールのインストールを行う。

## セットアップ

```sh
git clone https://github.com/kuromoka/dotfiles.git
cd dotfiles
bash install.sh
```

`install.sh` は以下を行う：

- Homebrew / zsh-autosuggestions / Rust / pnpm / Vite+ のインストール（未導入の場合のみ）
- 各設定ファイルをホームディレクトリへシンボリックリンク（既存ファイルは `.bak` にバックアップ）
- Git の補完・プロンプトスクリプトを `~/.zsh/` にダウンロード

## 構成

| パス | 内容 |
|---|---|
| `.zshrc` / `.zshenv` / `.zprofile` | zsh の設定 |
| `.gitconfig` / `.gitignore_global` | Git の設定 |
| `.vimrc` | Vim の設定 |
| `.tmux.conf` | tmux の設定 |
| `ghostty/` | Ghostty（ターミナル）の設定 |
| `karabiner/` | Karabiner-Elements（キーリマップ）の設定 |
| `yazi/` | yazi（ファイラー）の設定 |
| `claude/` | Claude Code の設定（下記） |

### claude/

Claude Code 用の設定。`~/.claude/` 以下にリンクされる。

| ファイル | 内容 |
|---|---|
| `settings.json` | 本体設定（permission mode、deny ルール、モデル、プラグイン等） |
| `statusline-command.sh` | ステータスライン表示スクリプト |
| `CLAUDE.md` | グローバル指示（下記の各ルールを import） |
| `codex-rescue.md` | OpenAI Codex プラグインへの委譲ルール |
| `model-delegate.md` | 下位モデルへの実装委譲ルール（Fable → Opus、Opus → Sonnet） |
| `skills/reload-rules/` | CLAUDE.md を再読み込みするスキル |

## 機密情報の扱い

シークレットや個人情報はリポジトリに含めず、ローカル専用ファイルに分離する：

- `~/.zshrc.local` — API トークン等の環境変数（`.zshrc` から読み込まれる）
- `~/.gitconfig.local` — Git の `name` / `email`（`.gitconfig` から include される）
