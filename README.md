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
| `templates/` | プロジェクトへ配置する雛形（symlink せず `gh` で取得して使う）。`loop/` はループエンジニアリング用 |

### claude/

Claude Code / Codex 用の設定。主に `~/.claude/` 以下にリンクされる（`AGENTS.md` は `~/.codex/` にも共有）。

| ファイル | 内容 |
|---|---|
| `settings.json` | 本体設定（permission mode、deny ルール、モデル、プラグイン等） |
| `statusline-command.sh` | ステータスライン表示スクリプト |
| `AGENTS.md` | 汎用エージェント設定（Claude Code / Codex 共通）。git/GitHub 操作・新規プロジェクトのデフォルト技術スタック。`~/.claude/AGENTS.md` と `~/.codex/AGENTS.md` の両方にリンクされる |
| `CLAUDE.md` | Claude 専用のグローバル指示（`AGENTS.md` と下記の各ルールを import） |
| `AGENTS.local.md` | マシン固有のローカル上書き（git 管理外）。`~/.claude/AGENTS.local.md` / `~/.codex/AGENTS.local.md` にリンク。Claude は CLAUDE.md の `@AGENTS.local.md` ネイティブ import、Codex は `AGENTS.md` 内の自然言語指示で読み込む |
| `codex-rescue.md` | OpenAI Codex プラグインへの委譲ルール |
| `model-delegate.md` | 下位モデルへの実装委譲ルール（Fable → Opus、Opus → Sonnet） |
| `skills/reload-rules/` | CLAUDE.md を再読み込みするスキル |

ローカル上書きの仕組み（ハイブリッド）:

- **Claude Code**: `CLAUDE.md` が `@AGENTS.local.md` をネイティブ import（プロンプトに確実に展開）。
- **Codex**: `@import` 非対応のため、共有 `AGENTS.md` に「Codex の場合は応答前に必ず `~/.codex/AGENTS.local.md` を読んで従え」と自然言語で指示し、エージェントがシェルで読み込む。
- `AGENTS.local.md` は `.gitignore`（`*.local.md`）で除外。`install.sh` は無ければ雛形を自動生成する。

## 機密情報の扱い

シークレットや個人情報はリポジトリに含めず、ローカル専用ファイルに分離する：

- `~/.zshrc.local` — API トークン等の環境変数（`.zshrc` から読み込まれる）
- `~/.gitconfig.local` — Git の `name` / `email`（`.gitconfig` から include される）
