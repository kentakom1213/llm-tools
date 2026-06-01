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
既定のモデルは `gemma4:e4b` です，

主なオプションは次の通りです，

| オプション | 説明 |
| --- | --- |
| `-m, --model MODEL` | 利用する Ollama モデルを指定します |
| `--max-diff-lines N` | Ollama に渡す staged diff の最大行数を指定します |
| `--full-diff` | staged diff 全体を Ollama に渡します |
| `--retry` | 自動整形も失敗した場合に 1 回だけ追加で再試行します |
| `--debug` | モデルの生出力を stderr に表示します |

例，

```console
llm-tools commit-msg --model qwen2.5-coder:7b --max-diff-lines 200
```

生成されるメッセージの type は，次のいずれかです，

```text
feat, fix, docs, style, refactor, test, chore, build, ci, perf
```

## 環境変数

| 変数 | 説明 |
| --- | --- |
| `LLM_TOOLS_HOME` | `llm-tools` 本体のディレクトリを上書きします |
| `OLLAMA_MODEL` | `commit-msg` で利用する既定の Ollama モデルを上書きします |
| `LLM_TOOLS_MAX_DIFF_LINES` | `commit-msg` で Ollama に渡す staged diff の既定最大行数を上書きします |

## ライセンス

MIT License です，
