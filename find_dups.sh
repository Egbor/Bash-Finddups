#!/bin/bash

basename=$(basename $0)
search_mode="name"
script_file="rm_dump.sh"

function set_parameters() {
    if [[ ! -d $1 ]]; then
	echo "$basename: directory not found"
	exit 2
    fi
    
    if [[ ! -z $2 ]]; then
	search_mode="$2"
    fi
    
    if [[ ! -z $3 ]]; then
	script_file="$3"
    fi
}

function find_all_files() {
    for item in "$1"/*; do
	#echo "$item"
	if [[ -d "$item" ]]; then
	    find_all_files "$item"
	elif [[ -f "$item" ]]; then
	    echo "$(sha1sum "$(realpath "$item")" 2> /dev/null)"
	fi
    done
}

function find_dups() {
    all_files=$(find_all_files "$1")

    echo "#!/bin/bash" > $script_file

    while [[ $all_files != "" ]]; do
	if [[ $search_mode == "name" ]]; then
	    target="$(echo "$all_files" | head -n 1 | sed 's/^[0-9a-f]*  //')"
	    target=$(basename "$target")
	    pattern="\/\Q$target\E$"
	elif [[ $search_mode == "cont" ]]; then
	    target="$(echo "$all_files" | head -n 1 | sed 's/  .*$//')"
	    pattern="^\Q$target\E"
	else
	    echo "$basename: search mode can be set as 'name' or 'cont'"
	    exit 3
	fi
	
	dup_files=$(echo "$all_files" | grep -P "$pattern")
	all_files=$(echo "$all_files" | grep -v -P "$pattern")
	
	echo "######----------------|$target|-----------" >> $script_file
	echo "$dup_files" | sed 's/^[0-9a-f]*  /#rm /' >> $script_file
    done
}

if [[ $# -lt 1 ]]; then
    echo "$basename: wrong number of parameters"
    exit 1
fi

set_parameters $1 $2 $3
find_dups $1
