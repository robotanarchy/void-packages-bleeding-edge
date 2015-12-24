#!/bin/bash
# Void Linux inofficial package overlay script
# Info: https://github.com/robotanarchy/void-packages-bleeding-edge

#
# FUNCTIONS
#

function STEP
{
	echo "$(tput bold)::: $1$(tput sgr0)"
}

# $1: package name
# $2: optional parameters
function update_repo()
{
	STEP "Updating $1 sources..."
	while IFS= read -r s; do
		local type="$(echo $s | cut -d ' ' -f 2)"
		local repo="$(echo $s | cut -d ' ' -f 3)"
		local subf="$(echo $s | cut -d ' ' -f 4)"
		local path="cache/$1/$subf"
		local curr="$PWD"
		
		echo "Updating $path..."
		mkdir -p "$path"
		cd "$path"
		case "$type" in
			"git" )
				require_progs git perl
				if [ -e ".git" ]; then
					git stash
					git pull
				else
					git clone $2 "$repo" .
					git submodule init
				fi
				git submodule update
				;;
			* )
				echo "$1: sources type $type not implemented!"
				exit 1
				;;
		esac
		cd "$curr"
	done < <(grep "^$1 " sources)
}

function merge_templates()
{
	STEP "Merging srcpkgs and shlibs into void-packages..."
	local srcpkgs="cache/void-packages/srcpkgs"
	
	for pkg in srcpkgs/*; do
		echo "merging $pkg...."
		rm -rf "$srcpkgs/$pkg"
		cp -r "$pkg" "$srcpkgs/"
	done
	
	echo "merging shlibs..."
	local shlibs="cache/void-packages/common/shlibs"
	mv "${shlibs}" "${shlibs}_"
	cat "shlibs" "${shlibs}_" > "${shlibs}"
	rm "${shlibs}_"
}

# $1: package name
function update_template()
{
	local s="$(grep "^$1 " sources | head --lines 1)"
	[[ "$s" == "" ]] && return 0
	
	local tmpl="cache/void-packages/srcpkgs/$1/template"
	if ! grep -q "version=LATEST" "$tmpl"; then
		echo "This package is in the sources file, but does not have"
		echo "a 'version=LATEST' line in the template. Please fix this!"
		echo "template path: srcpkgs/$1/template"
		exit 1
	fi
	
	local type="$(echo $s | cut -d ' ' -f 2)"
	local repo="$(echo $s | cut -d ' ' -f 3)"
	local subf="$(echo $s | cut -d ' ' -f 4)"
	local path="cache/$1/$subf"
	local curr="$PWD"
	
	cd "$path"
	case "$type" in
		"git" )
			local v="$(git rev-list --count HEAD).$(git rev-parse --short HEAD)"
			;;
	esac
	cd "$curr"
	echo "$1 version: $v"
	sed --in-place -s "s/version=LATEST/version=$v/" "$tmpl"
}

# $1: package name
function copy_sources()
{
	[ ! -d "cache/$1" ] && return 0
	echo "copying sources/$1 to masterdir/sources/..."
	local sources="cache/void-packages/masterdir/sources"
	mkdir -p "$sources"
	[ -e "sources/$1" ] && rm -rf "sources/$1"
	cp -rf "cache/$1" "$sources"
}

# $1: dependency, like name, name>1, name>=1, name<1
function pkg_name()
{
	[[ "$1" == *">"* ]] && echo "$(echo $1 | cut -d '>' -f 1)" && return
	[[ "$1" == *"<"* ]] && echo "$(echo $1 | cut -d '<' -f 1)" && return
	echo "$1"
}

# $1: program name (git, perl, ...)
function require_progs()
{
	for prog in "$@"; do
		type $1 >/dev/null 2>&1 && continue
		echo "ERROR: $prog not found, please install it and try again!"
		exit 1
	done
}


#
# MAIN CODE
#

if [ "$#" = 0 ]; then
	echo "Syntax:"
	echo "  $(basename $0) overlay-package1 [overlay-package2 [...]]"
	echo "For example:"
	echo "  $(basename $0) sway-git"
	exit 1
fi

# Check template files
for pkg in "$@"; do
    [ -e "srcpkgs/$pkg/template" ] && continue
	echo "ERROR: File not found: srcpkgs/$pkg/template"
	exit 1
done

update_repo void-packages --depth=1
merge_templates


# Parse dependencies
OVERLAY_ALL_PKGS=""
for pkg in "$@"
do
	STEP "Parsing dependencies of $pkg..."
	
	if [[ "$OVERLAY_ALL_PKGS" != *"$pkg"* ]]; then
		OVERLAY_ALL_PKGS="$OVERLAY_ALL_PKGS $pkg"
	fi
	
	for dep in $(source "srcpkgs/$pkg/template"; \
		echo $depends $makedepends $hostmakedepends) ;
	do
		name="$(pkg_name $dep)"
		if [ -e "srcpkgs/$name" ]; then
			echo "found overlay dependency $name"
			
			if [[ "$OVERLAY_ALL_PKGS" != *"$name"* ]]; then
				OVERLAY_ALL_PKGS="$OVERLAY_ALL_PKGS $name"
			fi
			
		elif [ ! -e "cache/void-packages/srcpkgs/$name" ]; then
			echo "ERROR: Dependency $dep (name parsed as $name) not" \
				" found in overlay or void packages!"
			exit 1
		fi
	done
done

for pkg in $OVERLAY_ALL_PKGS; do
	update_repo "$pkg"
	update_template "$pkg"
	copy_sources "$pkg"
done


# create a convinience symlink to binpkgs
if [ ! -e "binpkgs" ]; then
	echo "Creating binpkgs symlink..."
	mkdir -p cache/void-packages/hostdir/binpkgs
	ln -sf cache/void-packages/hostdir/binpkgs .
fi


STEP "Done!"
echo "You can build and install your packages now:"
echo "  ./xbps-src binary-bootstrap # (only required the first time)"
echo "  ./xbps-src pkg $@"
echo "  sudo xbps-install --repository=binpkgs $@"
