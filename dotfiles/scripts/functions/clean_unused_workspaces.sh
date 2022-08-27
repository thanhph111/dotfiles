#!/bin/bash

# This script is used to clean the VSCode workspaces that don't exist
# Reference: https://gist.github.com/3v1n0/8e27c06ca88159fdc140533608edbe37

clean_unused_workspaces() {
	# CONFIG_PATH=~/.config/Code
	CONFIG_PATH="$HOME/Library/Application Support/Code"

	for i in $CONFIG_PATH/User/workspaceStorage/*; do
		if [ -f $i/workspace.json ]; then
			folder="$(python3 -c "import sys, json; print(json.load(open(sys.argv[1], 'r'))['folder'])" $i/workspace.json 2>/dev/null | sed 's#^file://##;s/+/ /g;s/%\(..\)/\\x\1/g;')"

			if [ -n "$folder" ] && [ ! -d "$folder" ]; then
				echo "Removing workspace $(basename $i) for deleted folder $folder of size $(du -sh $i | cut -f1)"
				/usr/bin/env rm -rfv "$i"
			fi
		fi
	done
}
