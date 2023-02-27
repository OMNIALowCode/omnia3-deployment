#!/usr/bin/env bash
# Copyright (c) NumbersBelieve. All rights reserved.
#

set -e

set -u

set -o pipefail

exec 3>&1

if [ -t 1 ] && command -v tput > /dev/null; then

    ncolors=$(tput colors)
    if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
        bold="$(tput bold       || echo)"
        normal="$(tput sgr0     || echo)"
        black="$(tput setaf 0   || echo)"
        red="$(tput setaf 1     || echo)"
        green="$(tput setaf 2   || echo)"
        yellow="$(tput setaf 3  || echo)"
        blue="$(tput setaf 4    || echo)"
        magenta="$(tput setaf 5 || echo)"
        cyan="$(tput setaf 6    || echo)"
        white="$(tput setaf 7   || echo)"
    fi
fi

invocation='say "Calling: ${yellow:-}${FUNCNAME[0]} ${green:-}$*${normal:-}"'

say() {
	printf "%b\n" "${cyan:-}omnia-install:${normal:-} $1" >&3
}

read_dom() {
    local IFS=\>
    read -d \< ENTITY CONTENT
    local ret=$?
    TAG_NAME=${ENTITY%% *}
    ATTRIBUTES=${ENTITY#* }
    return $ret
}

unzip-from-link() {
	eval $invocation
	
	local download_link=$1; shift || return 1
	local destination_dir=${1:-}
	local temporary_dir

	rm -rf "$destination_dir"/*
 
	temporary_dir=$(mktemp -d) \
	&& curl -LO "${download_link:-}" \
	&& unzip -o -d "$temporary_dir" \*.zip \
	&& rm -rf \*.zip \
	&& mv "$temporary_dir"/* "$destination_dir" \
	&& rm -rf "$temporary_dir"
}


download_latest_omnia_version() {
	eval $invocation
	local omnia_feed=$(curl -sSL https://mymiswebdeploy.blob.core.windows.net/omnia3/platform/updateFeed.xml)
	echo "$omnia_feed"
	return $?
}

update_omnia() {
	eval $invocation
	
	local temp_file=$(mktemp)
	download_latest_omnia_version > "$temp_file"

	while read_dom; do
		if [[ $TAG_NAME = "Version" ]]; then
			eval local $ATTRIBUTES
			break;
		fi
	done < "$temp_file"
		
	say "Download package"
	unzip-from-link "$PackageBinaries" "/home/omnia/bin"
	systemctl restart omnia
	
	return $?
}




update_omnia