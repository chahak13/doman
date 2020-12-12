#! /bin/sh
source "${0%/*}/colors.sh"

options=()
_parse_links() {
    : 'Parser that removes the comments and returns an array containing
      elements that are pipe (|) separated pairs of source and destination
      for each links to be generated.
      '
    while read line; do
	local src=$(awk -F': ' '{print $2}' <<< "${line}")
	local dest=$(awk -F': ' '{print $1}' <<< "${line}" | sed "s#~#${HOME}#")
	options+=("${src}|${dest}")
    done < <(grep -Ev '^[[:space:]]*#' "$1")
}

_create_symlinks() {
    : 'This function does the checking and creation of symlinks. It first calls
      the `_parse_links` function and expects it to populate the options array
      with elements that are strings containing pipe(|) delimeted source and
      destination for the symlinks to be created (ref. _parse_links). Thereafter
      it performs various sanity checks on the sources and destinations, and
      then creates the symlinks. It also prints useful messages to the stdout
      for reference.
      '  
    _parse_links $1

    for option in "${options[@]}"; do
	local src=$(realpath "${0%/*}/$(cut -d'|' -f 1 <<< ${option})")
	local dest=$(cut -d'|' -f 2 <<< ${option})
	local cmd="ln -s ${src} ${dest}"
	if [[ -f "${src}" ]]; then
	    if [[ -L ${dest} ]]; then
		if [[ -f $(realpath ${dest}) ]]; then
		    # Write proper error message and add --force option to override
		    # existing links
		    printf "${RED}${dest} already points to $(realpath ${dest})\n"
		else
		    # Write proper error mentioning --clean option
		    printf "${RED}Broken link!!: ${NC}${dest}\n"
		fi
	    elif [[ -f ${dest} ]]; then
		# Write proper error message and add option
		# to backup original files and create links as per config
		printf "A regular file already exists at ${dest}\n"
	    else
		if $($cmd &>/dev/null); then
		    printf "${GREEN} Links succesfully created: ${src} => ${dest}\n"
		else
		    printf "${RED} Something went wrong in the linking.\n"
		fi
	    fi
	else
	    printf "${RED}Source file mentioned in config doesn't exist: ${NC}${src}\n"
	fi
	    
    done
    
}

_create_symlinks $1
