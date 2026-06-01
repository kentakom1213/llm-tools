typeset -g config_file="${LLM_TOOLS_CONFIG:-${XDG_CONFIG_HOME:-${HOME:-}/.config}/llm-tools/config.toml}"
typeset -g model="gemma4:e2b"
typeset -g debug=0
typeset -g max_diff_lines=120
typeset -g name_only_lines=2000
typeset -g full_diff=0
typeset -g retry=0
typeset -ga ollama_parameters

trim_value () {
	local value="$1"

	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	print -r -- "$value"
}

strip_toml_comment () {
	local line="$1"
	local output="" quote="" char previous=""
	local i

	for (( i = 1; i <= ${#line}; i++ ))
	do
		char="${line[i]}"

		if [[ -z "$quote" && "$char" == "#" ]]
		then
			break
		fi

		output+="$char"

		if [[ "$char" == '"' && "$previous" != "\\" && "$quote" != "'" ]]
		then
			if [[ "$quote" == '"' ]]
			then
				quote=""
			else
				quote='"'
			fi
		elif [[ "$char" == "'" && "$quote" != '"' ]]
		then
			if [[ "$quote" == "'" ]]
			then
				quote=""
			else
				quote="'"
			fi
		fi

		previous="$char"
	done

	trim_value "$output"
}

unquote_toml_value () {
	local value="$1"

	if [[ "$value" == \"*\" && "$value" == *\" ]]
	then
		value="${value[2,-2]}"
	elif [[ "$value" == \'*\' && "$value" == *\' ]]
	then
		value="${value[2,-2]}"
	fi

	print -r -- "$value"
}

load_git_message_config () {
	local command_name="$1"
	local file="$2"
	local section="" line key value parameter_key

	[[ -f "$file" ]] || return 0

	while IFS= read -r line || [[ -n "$line" ]]
	do
		line="$(strip_toml_comment "$line")"
		[[ -n "$line" ]] || continue

		if [[ "$line" == \[*\] ]]
		then
			section="${line[2,-2]}"
			continue
		fi

		[[ "$line" == *=* ]] || continue
		key="$(trim_value "${line%%=*}")"
		value="$(trim_value "${line#*=}")"
		value="$(unquote_toml_value "$value")"

		case "$section:$key" in
			(${command_name}:model)
				model="$value"
				;;
			(${command_name}:max_diff_lines | ${command_name}:max-diff-lines)
				max_diff_lines="$value"
				;;
			(${command_name}:name_only_lines | ${command_name}:name-only-lines)
				name_only_lines="$value"
				;;
			(${command_name}:temperature)
				ollama_parameters+=( "temperature=$value" )
				;;
			(${command_name}:top_p | ${command_name}:top-p)
				ollama_parameters+=( "top_p=$value" )
				;;
			(${command_name}:top_k | ${command_name}:top-k)
				ollama_parameters+=( "top_k=$value" )
				;;
			(${command_name}:seed)
				ollama_parameters+=( "seed=$value" )
				;;
			(${command_name}:num_ctx | ${command_name}:num-ctx)
				ollama_parameters+=( "num_ctx=$value" )
				;;
			(${command_name}.parameters:*)
				parameter_key="${key//-/_}"
				ollama_parameters+=( "$parameter_key=$value" )
				;;
		esac
	done < "$file"
}

apply_git_message_env () {
	model="${OLLAMA_MODEL:-$model}"
	max_diff_lines="${LLM_TOOLS_MAX_DIFF_LINES:-$max_diff_lines}"
	name_only_lines="${LLM_TOOLS_NAME_ONLY_LINES:-$name_only_lines}"
}

parse_git_message_option () {
	case "${1:-}" in
		(-m | --model)
			(( $# >= 2 )) || die "missing value for --model" 2
			model="$2"
			REPLY=2
			return 0
			;;
		(--temperature)
			(( $# >= 2 )) || die "missing value for --temperature" 2
			ollama_parameters+=( "temperature=$2" )
			REPLY=2
			return 0
			;;
		(--top-p)
			(( $# >= 2 )) || die "missing value for --top-p" 2
			ollama_parameters+=( "top_p=$2" )
			REPLY=2
			return 0
			;;
		(--top-k)
			(( $# >= 2 )) || die "missing value for --top-k" 2
			ollama_parameters+=( "top_k=$2" )
			REPLY=2
			return 0
			;;
		(--seed)
			(( $# >= 2 )) || die "missing value for --seed" 2
			ollama_parameters+=( "seed=$2" )
			REPLY=2
			return 0
			;;
		(--num-ctx)
			(( $# >= 2 )) || die "missing value for --num-ctx" 2
			ollama_parameters+=( "num_ctx=$2" )
			REPLY=2
			return 0
			;;
		(--ollama-parameter)
			(( $# >= 2 )) || die "missing value for --ollama-parameter" 2
			ollama_parameters+=( "$2" )
			REPLY=2
			return 0
			;;
		(--max-diff-lines)
			(( $# >= 2 )) || die "missing value for --max-diff-lines" 2
			[[ "$2" == <-> ]] || die "invalid value for --max-diff-lines: $2" 2
			max_diff_lines="$2"
			REPLY=2
			return 0
			;;
		(--name-only-lines)
			(( $# >= 2 )) || die "missing value for --name-only-lines" 2
			[[ "$2" == <-> ]] || die "invalid value for --name-only-lines: $2" 2
			name_only_lines="$2"
			REPLY=2
			return 0
			;;
		(--full-diff)
			full_diff=1
			REPLY=1
			return 0
			;;
		(--retry)
			retry=1
			REPLY=1
			return 0
			;;
		(--debug)
			debug=1
			REPLY=1
			return 0
			;;
	esac

	return 1
}

validate_git_message_options () {
	local parameter key value

	require_command git
	require_command ollama

	[[ "$max_diff_lines" == <-> ]] || die "invalid value for LLM_TOOLS_MAX_DIFF_LINES: $max_diff_lines" 2
	[[ "$name_only_lines" == <-> ]] || die "invalid value for LLM_TOOLS_NAME_ONLY_LINES: $name_only_lines" 2

	for parameter in "${ollama_parameters[@]}"
	do
		[[ "$parameter" == *=* ]] || die "invalid Ollama parameter: $parameter" 2
		key="${parameter%%=*}"
		value="${parameter#*=}"
		[[ "$key" == [A-Za-z_][A-Za-z0-9_]* ]] || die "invalid Ollama parameter name: $key" 2
		[[ -n "$value" ]] || die "missing value for Ollama parameter: $key" 2
	done
}

collect_git_diff_context () {
	local files_command="$1"
	local numstat_command="$2"
	local name_status_command="$3"
	local stat_command="$4"
	local diff_command="$5"
	local empty_message="$6"
	local empty_hint="${7:-}"
	local name_only numstat added deleted path_field sample_limit sample_lines diff_sample

	name_only="$(eval "$files_command")"

	if [[ -z "$name_only" ]]
	then
		print -ru2 -- "$empty_message"
		[[ -z "$empty_hint" ]] || print -ru2 -- "$empty_hint"
		exit 1
	fi

	numstat="$(eval "$numstat_command")"
	changed_lines=0
	binary_files=0

	while IFS=$'\t' read -r added deleted path_field
	do
		[[ -n "${added:-}${deleted:-}" ]] || continue

		if [[ "$added" == <-> ]]
		then
			changed_lines=$(( changed_lines + added ))
		else
			binary_files=$(( binary_files + 1 ))
		fi

		if [[ "$deleted" == <-> ]]
		then
			changed_lines=$(( changed_lines + deleted ))
		fi
	done <<< "$numstat"

	name_only_mode=0
	if (( ! full_diff && name_only_lines > 0 && changed_lines > name_only_lines ))
	then
		name_only_mode=1
	fi

	if (( name_only_mode ))
	then
		diff_mode="name-only"
		changed_files="$name_only"
		diff_stat="(skipped: large diff; using file names only)"
		truncated=1
		diff_line_limit="name-only"
		git_diff=""
	elif (( full_diff ))
	then
		diff_mode="diff"
		changed_files="$(eval "$name_status_command")"
		diff_stat="$(eval "$stat_command")"
		truncated=0
		diff_line_limit="full"
		git_diff="$(eval "$diff_command")"
	elif (( max_diff_lines == 0 ))
	then
		diff_mode="diff"
		changed_files="$(eval "$name_status_command")"
		diff_stat="$(eval "$stat_command")"
		truncated=1
		diff_line_limit="$max_diff_lines"
		git_diff=""
	else
		diff_mode="diff"
		changed_files="$(eval "$name_status_command")"
		diff_stat="$(eval "$stat_command")"
		diff_line_limit="$max_diff_lines"
		sample_limit=$(( max_diff_lines + 1 ))
		diff_sample="$(eval "$diff_command" | sed -n "1,${sample_limit}p")"
		if [[ -n "$diff_sample" ]]
		then
			sample_lines="$(print -- "$diff_sample" | wc -l | tr -d '[:space:]')"
		else
			sample_lines=0
		fi

		if (( sample_lines > max_diff_lines ))
		then
			truncated=1
			git_diff="$(print -- "$diff_sample" | sed -n "1,${max_diff_lines}p")"
		else
			truncated=0
			git_diff="$diff_sample"
		fi
	fi

	if [[ -n "$git_diff" ]]
	then
		included_diff_lines="$(print -- "$git_diff" | wc -l | tr -d '[:space:]')"
	else
		included_diff_lines=0
	fi
}

run_git_message_model () {
	local model="$1"
	local parameter key value
	typeset -a parameter_commands

	for parameter in "${ollama_parameters[@]}"
	do
		key="${parameter%%=*}"
		value="${parameter#*=}"
		parameter_commands+=( "/set parameter $key $value" )
	done

	if (( ${#parameter_commands[@]} > 0 ))
	then
		{
			printf "%s\n" "${parameter_commands[@]}"
			cat
		} | run_ollama "$model"
	else
		run_ollama "$model"
	fi
}
