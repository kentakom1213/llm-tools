# util

zsh で使う個人用ユーティリティをまとめたディレクトリです，

現在は，LLM への入力作成や Git コミットメッセージ生成を補助する `llm-tools` を提供しています，

## セットアップ

zsh の設定ファイルから `init.sh` を読み込みます，

```zsh
source /path/to/util/init.sh
```

この設定により，`llm-tools` 関数が利用できるようになります，

## 使い方

```console
llm-tools <subcommand> [args]
```

利用できるサブコマンドは次の通りです，

```console
llm-tools files <file...>
llm-tools commit-msg
llm-tools pr-msg
```

バージョンは次のコマンドで確認できます，

```console
llm-tools --version
```

## `files`

指定したファイルを，LLM に貼り付けやすい Markdown コードブロック形式で出力します，

```console
llm-tools files README.md llm-tools.zsh
```

区切り文字は `-s` または `--separator` で変更できます，

```console
llm-tools files --separator '---' README.md
```

存在しないファイルは `MISSING` セクションとして出力されます，

## `commit-msg`

Git の staged changes から Conventional Commits 形式のコミットメッセージを 1 行生成します，

```console
git add -p
llm-tools commit-msg
```

このサブコマンドは `git` と `ollama` を利用します，
利用するモデルは設定ファイルまたは `OLLAMA_MODEL` で指定します，
設定ファイルは `${XDG_CONFIG_HOME:-$HOME/.config}/llm-tools/config.toml` から読み込まれます，

主なオプションは次の通りです，

| オプション | 説明 |
| --- | --- |
| `-m, --model MODEL` | 利用する Ollama モデルを指定します |
| `--temperature N` | Ollama の `temperature` パラメータを指定します |
| `--top-p N` | Ollama の `top_p` パラメータを指定します |
| `--top-k N` | Ollama の `top_k` パラメータを指定します |
| `--seed N` | Ollama の `seed` パラメータを指定します |
| `--num-ctx N` | Ollama の `num_ctx` パラメータを指定します |
| `--ollama-parameter KEY=VALUE` | 任意の Ollama モデルパラメータを指定します |
| `--max-diff-lines N` | Ollama に渡す staged diff の最大行数を指定します |
| `--large-change-lines N` | 二段階生成に切り替える変更行数を指定します |
| `--huge-change-lines N` | 巨大変更の機械要約に切り替える変更行数を指定します |
| `--huge-change-files N` | 巨大変更の機械要約に切り替える変更ファイル数を指定します |
| `--full-diff` | staged diff 全体を Ollama に渡します |
| `--retry` | 自動整形も失敗した場合に 1 回だけ追加で再試行します |
| `--debug` | モデルの生出力を stderr に表示します |

例，

```console
llm-tools commit-msg --model qwen2.5-coder:7b --max-diff-lines 200
llm-tools commit-msg --temperature 0 --top-p 0.2 --seed 1
llm-tools commit-msg --ollama-parameter repeat_penalty=1.1
```

設定例，

```toml
[commit-msg]
model = "gemma4:e2b"
max_diff_lines = 120
large_change_lines = 800
huge_change_lines = 3000
huge_change_files = 300
temperature = 0
seed = 1
num_ctx = 8192

[commit-msg.parameters]
repeat_penalty = 1.1
```

`[commit-msg].model` は必須です，
ただし `OLLAMA_MODEL` を指定した場合は設定ファイルの `model` を省略できます，
設定値は `組み込み既定値 < TOML < 環境変数 < CLI 引数` の順に上書きされます，

生成されるメッセージの type は，次のいずれかです，

```text
feat, fix, docs, style, refactor, test, chore, build, ci, perf
```

## `pr-msg`

Git の現在のブランチと base ブランチの差分から，PR のタイトルと本文を生成します，

```console
llm-tools pr-msg
llm-tools pr-msg --base origin/main
```

このサブコマンドは `git` と `ollama` を利用します，
base は `origin/HEAD`，`origin/main`，`main`，`origin/master`，`master` の順に自動検出されます，
検出結果を変えたい場合は `--base REF` を指定します，

`commit-msg` と同じ Ollama 関連オプション，diff 制限オプション，`--retry`，`--debug` が利用できます，

設定例，

```toml
[pr-msg]
model = "gemma4:e2b"
max_diff_lines = 300
large_change_lines = 1000
huge_change_lines = 5000
huge_change_files = 500
temperature = 0
seed = 1
num_ctx = 8192

[pr-msg.parameters]
repeat_penalty = 1.1
```

`[pr-msg].model` も必須です，
ただし `OLLAMA_MODEL` を指定した場合は設定ファイルの `model` を省略できます，

## 環境変数

| 変数 | 説明 |
| --- | --- |
| `LLM_TOOLS_HOME` | `llm-tools` 本体のディレクトリを上書きします |
| `LLM_TOOLS_CONFIG` | `llm-tools` の TOML 設定ファイルを上書きします |
| `OLLAMA_MODEL` | `commit-msg` / `pr-msg` で利用する Ollama モデルを上書きします |
| `LLM_TOOLS_MAX_DIFF_LINES` | `commit-msg` / `pr-msg` で Ollama に渡す diff の既定最大行数を上書きします |
| `LLM_TOOLS_NAME_ONLY_LINES` | `commit-msg` / `pr-msg` でファイル名のみへ切り替える変更行数を上書きします |

## ライセンス

MIT License です，
