# Repeat a command over a specified interval
def repeat [d: duration, command: closure] {
  loop {
	print (do $command);
	sleep $d;
  }
}

# Runs scc but converts it into a format nushell can work with
# and only savesthe columns I care about
def nu-scc [] {
  scc --format json | jq | from json | select Name Bytes Lines Code Comment Blank
}

# Check if in git repo
def in_git_repo [] {
  git rev-parse --abbrev-ref HEAD | complete | get stderr | is-empty
}

# Add git information to prompt, if in repo
def git_left_prompt [in_left_prompt] {

  # If we're in a repo
  let currently_in_git_repo = in_git_repo

  if $currently_in_git_repo {

    # Get the branch info first
    let branch_info = git branch -l
      | lines
      | filter {|e| $e | str contains "*" }
      | each {|e| $e | str replace "* " "="}
      | get 0

	# Base the color of this text on the status of the repo
	# red = uncommited stuff
	# green = up to date
	let git_status_color = if (git status -s | is-empty) {
	  ansi green_dimmed
	} else {
	  ansi red_dimmed
	}

    # construct the prompt
    $"($in_left_prompt)(ansi reset)[($git_status_color)($branch_info)(ansi reset)]"

  } else {
    # otherwise just return the normal prompt
    $in_left_prompt
  }
}

# Set what the prompt looks like
$env.PROMPT_COMMAND = {||

	# Statement in match is getting our current directory relative to home
    let dir = match (do -i { $env.PWD | path relative-to $nu.home-path }) {
		
		# If for some reason it is null, our dir is just pwd
        null => $env.PWD
		# If empty, then we are home
        '' => '~'
		# Otherwise just get name of dir we are in
        $relative_pwd => ($relative_pwd | path basename)
    }

	# Red if root
    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })

	# Wrap text with color
    let path_segment = $"($path_color)($dir)(ansi reset)"
	

	# "char path_sep" resolves to the path seperator for this OS
	# This str replace finds all instances of the seperator and replaces it with a colored seperator
	let normal_prompt = $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"

	# Show branch information if in branch
	git_left_prompt $normal_prompt
}

# Default editor
$env.config.buffer_editor = "nvim"

# When editing commands, use vi shortcuts
$env.config.edit_mode = 'vi'
