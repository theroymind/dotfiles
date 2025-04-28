#!/usr/bin/env bash

remoteName=${1:-origin}
branch=`git rev-parse --abbrev-ref HEAD`
last_commit_message=$(git log -1 --pretty=%B)

remote=`git remote -v | grep "(push)$" | grep $remoteName`
regex="origin[[:space:]]+git@([A-Za-z\.]+)[\:|\/](.*)/(.*).git"

if [[ $remote =~ $regex ]]; then
    server=${BASH_REMATCH[1]}
    group=${BASH_REMATCH[2]}
    project=${BASH_REMATCH[3]}
else
    echo "error: unsupported remote"
    exit 1
fi


target="master"
prefix="(Master)"
labels="merge-to-master"

if [[ "$branch" == *STAGING ]]; then
    target="staging"
    prefix="(Staging)"
    labels="merge-to-preprod"
fi

if [[ "$branch" == *PREPROD ]]; then
    target="preprod"
    prefix="(Preprod)"
    labels="merge-to-preprod"
fi

title="$prefix $last_commit_message"

if [[ "$server" == github.com ]]; then
echo "https://github.com/$(git repofullname)/compare/$target...$branch?expand=1&title=$title&labels=$labels"
open "https://github.com/$(git repofullname)/compare/$target...$branch?expand=1&title=$title&labels=$labels"
else
    if [[ "$target" == master ]]; then
        open "https://$server/$group/$project/merge_requests/new?merge_request%5Bforce_remove_source_branch%5D=1&merge_request%5Bsource_branch%5D=$branch&merge_request%5B"
    else
        open "https://$server/$group/$project/merge_requests/new?merge_request%5Bforce_remove_source_branch%5D=1&merge_request%5Bsource_branch%5D=$branch&merge_request%5Btarget_branch%5D=$target"
    fi
fi