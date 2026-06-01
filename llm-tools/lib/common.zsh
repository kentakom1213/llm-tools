die () {
	print -ru2 -- "$1"
	exit "${2:-1}"
}

require_command () {
	local name="$1"

	command -v "$name" >/dev/null 2>&1 || {
		die "required command not found: $name"
	}
}

llm_tools_version () {
	local version_file="$LLM_TOOLS_HOME/VERSION"

	if [[ -f "$version_file" ]]
	then
		print -- "llm-tools $(<"$version_file")"
	else
		print -- "llm-tools unknown"
	fi
}

run_ollama () {
	local model="$1"

	require_command ollama

	ollama run "$model"
}
