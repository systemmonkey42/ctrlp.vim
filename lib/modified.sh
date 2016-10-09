#!/bin/sh -e
GITROOT=$(git rev-parse --show-cdup)

{
	if [ -e "${GITROOT}.git/MERGE_HEAD" ] || [ -d "${GITROOT}.git/rebase-merge" ] || [ -d "${GITROOT}.git/rebase-apply" ] || [ -e "${GITROOT}.git/CHERRY_PICK_HEAD" ]; then
		git status --porcelain --untracked=no --
	else
		git status --porcelain --untracked-files=all --
	fi
} | {
	# 'safe' version, with ~'s escaped
	SAFE_GITROOT=$( echo "${GITROOT}" | sed -e 's/\~/\\~/g')
	sed "s~^...~${SAFE_GITROOT}~"
}
