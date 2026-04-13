# dotfiles — CLAUDE.md

このリポジトリは GitHub public で公開されている。以下のルールを必ず守ること。

## 機密情報・個人情報の扱い

- APIトークン・パスワード等の秘密情報は `.zshrc` に直接書かない。`~/.zshrc.local` に書き、`.zshrc` では `[ -f ~/.zshrc.local ] && source ~/.zshrc.local` で読み込む。
- Git の `name` / `email` は `.gitconfig` に書かない。`~/.gitconfig.local` に書き、`.gitconfig` では `[include] path = ~/.gitconfig.local` で読み込む。
- `*.local` ファイルは `.gitignore` で除外済み。

## パスの書き方

- ユーザー名を含むパスをファイル内に書かない。`$HOME` または `~` を使う。
- ローカル固有のディレクトリパスをドキュメントや設定ファイルに書かない。

## install.sh

- 新しい設定ファイルを追加したら `install.sh` のシンボリックリンクマッピングにも追記する。

## コミット前チェック

- ユーザー名やローカル固有のパスが書かれていないか確認する。
- メールアドレス・APIトークン・パスワードが含まれていないか確認する。
