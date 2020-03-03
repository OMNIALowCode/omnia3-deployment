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

install_nginx() {
	eval $invocation
	apt-get install nginx=1.14.0-0ubuntu1.7 --assume-yes
	return $?
}

install_netcore() {
	eval $invocation
	curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -c Current
	wget -q https://packages.microsoft.com/config/ubuntu/$ubuntu_version/packages-microsoft-prod.deb
	dpkg -i packages-microsoft-prod.deb
	apt-get install apt-transport-https=1.6.12 --assume-yes
	add-apt-repository universe
	apt-get update
	apt-get install dotnet-sdk-3.1 --assume-yes
	return $?
}

install_psql() {
	eval $invocation
	
	apt-get install postgresql=10+190ubuntu0.1 --assume-yes
	apt-get install postgresql-contrib=10+190ubuntu0.1 --assume-yes
	sudo -u postgres createuser --superuser omnia -P
	
	return $?
}

download_latest_omnia_version() {
	eval $invocation
	local omnia_feed=$(curl -sSL https://mymiswebdeploy.blob.core.windows.net/omnia3/platform/updateFeed.xml)
	echo "$omnia_feed"
	return $?
}

install_omnia() {
	eval $invocation
	
	local temp_file=$(mktemp)
	download_latest_omnia_version > "$temp_file"

	while read_dom; do
		if [[ $TAG_NAME = "Version" ]]; then
			eval local $ATTRIBUTES
			break;
		fi
	done < "$temp_file"
	
	mkdir -p "/home/omnia"
	
	say "Download package"
	unzip-from-link "$PackageFull" "/home/omnia"
	
	cp /home/omnia/setup/nginx/* /etc/nginx/ -r
	service nginx reload
	
	return $?
}

get_legacy_os_name_from_platform() {
    eval $invocation

    platform="$1"
    case "$platform" in
        "ubuntu.16.04")
            echo "ubuntu.16.04"
            return 0
            ;;
        "ubuntu.18.04")
            echo "ubuntu.18.04"
            return 0
            ;;
    esac
    return 1
}

check_if_linux_and_ubuntu() {
	eval $invocation

	local uname=$(uname)
	if [ "$uname" = "Linux" ]; then
		if [ -e /etc/os-release ]; then
            . /etc/os-release
            os=$(get_legacy_os_name_from_platform "$ID.$VERSION_ID" || echo "")
            if [[ "$os" == "ubuntu.18.04" || "$os" == "ubuntu.16.04" ]]; then
                return 0
            fi
        fi
	fi
	
	say "Linux and Ubuntu 16.04 or 18.04 are required"
	return 1;
}

get_ubuntu_version() {
	eval $invocation
	
	if [ -e /etc/lsb-release ]; then
		. /etc/lsb-release
	
		echo $DISTRIB_RELEASE;
		return 0;
	fi
	
	say "Unable to get Ubuntu version"
	return 1;
}

install_services() {
	eval $invocation
	
	cp /home/omnia/setup/services/*.service /etc/systemd/system/
	systemctl daemon-reload
	cd /etc/systemd/system/
	systemctl enable omnia omnia-*
	
	return $?
}

check_if_linux_and_ubuntu
ubuntu_version=$(get_ubuntu_version)
requires_pqsl=true

if [ "$#" -eq 0 ]; then
  say "Default omnia-install behaviour including PostgreSQL installation"
else
	if [ "$1" = "--nopsql" ]; then 
		requires_pqsl=false
		say "Switch omnia-install behaviour excluding PostgreSQL installation"
	fi
fi

say "Create user omnia if required"
id -u omnia &>/dev/null || useradd omnia -s /sbin/nologin

apt-get update
apt-get install unzip --assume-yes

install_nginx
install_netcore

if [ "$requires_pqsl" = true ]; then
	install_psql
fi

install_omnia
install_services