" --- 表示・外観の設定 ---
set number         " 行番号を表示
set cursorline     " 現在の行をハイライト
set laststatus=2   " ステータスラインを常に表示
set showmatch      " 括弧の入力時に対応する括弧を光らせる
set helpheight=999 " ヘルプを画面いっぱいに開く
syntax on          " コードをカラー表示

" --- インデント・空白の設定 ---
set expandtab      " タブ入力を空白に変換
set tabstop=4      " タブを何文字分として表示するか
set shiftwidth=4   " 自動インデント時のズレ幅
set softtabstop=4  " 連続した空白をタブのように削除
set autoindent     " 改行時に前の行のインデントを継続
set smartindent    " 改行時に適切なインデントを自動挿入

" --- 検索の設定 ---
set ignorecase     " 検索時に大文字小文字を区別しない
set smartcase      " 検索語に大文字が含まれている場合は区別する
set incsearch      " タイピング中に検索結果を反映
set hlsearch       " 検索結果をハイライト（Esc連打で消す設定は下記）

" --- 操作・システムの設定 ---
set clipboard=unnamed,unnamedplus " クリップボードをシステムと共有
set mouse=a        " マウス操作を有効化
set noswapfile     " スワップファイルを作成しない
set nobackup       " バックアップファイルを作成しない
set encoding=utf-8 " 文字コードをUTF-8に

