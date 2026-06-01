_llm_tools_default_home="${${(%):-%N}:A:h}/llm-tools"

llm-tools () {
	emulate -L zsh
	setopt pipefail

	local llm_tools_home="${LLM_TOOLS_HOME:-$_llm_tools_default_home}"
	local command_dir="$llm_tools_home/commands"
	local version_file="$llm_tools_home/VERSION"

	usage () {
		cat <<'EOF'
Usage:
  llm-tools <subcommand> [args]

Subcommands:
  files <file...>
  commit-msg
  pr-msg
EOF
	}

	local cmd="${1:-}"

	if [[ -z "$cmd" ]]
	then
		usage
		return 2
	fi

	case "$cmd" in
		(-h | --help)
			usage
			return 0
			;;
		(--version)
			if [[ -f "$version_file" ]]
			then
				print -- "llm-tools $(<"$version_file")"
			else
				print -- "llm-tools unknown"
			fi
			return 0
			;;
	esac

	shift

	local command_path="$command_dir/$cmd"

	if [[ ! -x "$command_path" ]]
	then
		print -ru2 -- "llm-tools: unknown subcommand: $cmd"
		return 2
	fi

	LLM_TOOLS_HOME="$llm_tools_home" "$command_path" "$@"
}
