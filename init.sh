if [ -n "${ZSH_VERSION-}" ]; then
  _UTIL_DIR="${0:A:h}"
fi

# llm-tools を読み込む
source "${_UTIL_DIR}/llm-tools.zsh"

unset _UTIL_DIR
