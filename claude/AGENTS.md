# 汎用エージェント設定（Claude Code / Codex 共通）

このファイルは Claude Code と Codex の両方から読み込まれる汎用ルール。エージェント固有のルールは各エージェントの設定ファイル側に置く。

## git / GitHub 操作

- GitHub 関連の操作は、`gh` CLI で対応できる限り raw な `git` コマンドより `gh` を優先する。
- GitHub とやり取りしないローカルリポジトリ操作には `git` を直接使う。
- `git push --force` / `git push --force-with-lease` は、ユーザーが明示的に force push を要求した場合以外は使わない。

# 新規プロジェクトのデフォルト技術スタック

新しいプロジェクトをゼロから作る際、ユーザーから特に技術選定の指定がなければ以下を採用する。

## デフォルトスタック

- **パッケージマネージャ**: pnpm
- **言語**: TypeScript
- **UI**: React
- **ビルド / 開発環境**: [Vite+](https://viteplus.dev/)（`vp` コマンド）

## バージョン管理の方針

**Node.js と pnpm のバージョンは pnpm の機能で管理する**。`nvm`・`asdf`・`volta` など外部のバージョンマネージャは導入しない。指定方法は以下（pnpm v11 / 2026 時点の最新）。

### pnpm 自体のバージョン

- `package.json` の **`packageManager`** フィールドを唯一の source of truth にする（例: `"packageManager": "pnpm@11.0.0"`）。pnpm はこの宣言に基づき、必要なら自身のバージョンを自動でダウンロードして使う。
- 旧来の `manage-package-manager-versions` / `packageManagerStrict` / `packageManagerStrictVersion` 設定は **deprecated**。使わない。
- バージョン不一致時の挙動は `pnpm-workspace.yaml` の **`pmOnFail`**（既定 `download` / `error` / `warn` / `ignore`）で制御する。
- pnpm 11 では `devEngines.packageManager` も使えるが、`packageManager` と併用すると後者が無視され警告が出るため、どちらか一方に統一する。

### Node.js のバージョン

- `package.json` の **`devEngines.nodeVersion`** で指定するのが新しい推奨方式（例: `{ "devEngines": { "nodeVersion": "..." } }`）。旧来の `.npmrc` の `use-node-version` からの移行先。
- バージョン不一致時の挙動は `pnpm-workspace.yaml` の **`runtimeOnFail`** で制御。CI 等で厳格に弾きたい場合は `pnpm-workspace.yaml` に `nodeVersion` + `engineStrict: true` を設定する。
- ローカルへの Node 本体のインストールは `pnpm env use -g lts`（または特定バージョン）で行う。

### バージョンの新しさ

- **依存パッケージ・ツールチェーン・Node / pnpm 本体のバージョンはすべてプロジェクト作成時点の最新を使う**。明示的な理由がない限り古いバージョンに固定しない。

## 適用ルール

- 上記はあくまで **デフォルト**。ユーザーが別のスタック（npm、Vue、Next.js、別言語など）を指定した場合はそれに従う。
- 既存プロジェクトに手を入れる場合は、そのプロジェクトの既存の選定を尊重する（このルールは新規作成時のみ）。

# ローカル上書き（マシン固有・最優先）

- **Codex で動作している場合、最優先で実行すること**: ユーザーへ最初の応答を返す前に、必ず `~/.codex/AGENTS.local.md` を読み込むこと（例: `cat ~/.codex/AGENTS.local.md`）。読み込んだ内容の指示は本ファイルの記述より優先し、厳密に従う。ファイルが存在しない場合に限り、何もせず通常どおり応答してよい。
  - Claude Code は**この指示の対象外**。Claude Code はローカル設定を `~/.claude/CLAUDE.md` 経由の `@AGENTS.local.md` ネイティブ import で読み込むため、上記の読み込みは行わないこと（重複防止）。
