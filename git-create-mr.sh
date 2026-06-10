#!/usr/bin/env bash

# Percent-encode a string for safe use in a URL query value (UTF-8 aware).
urlencode() {
    local LC_ALL=C
    local string="$1" out="" i c hex
    for (( i = 0; i < ${#string}; i++ )); do
        c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) out+="$c" ;;
            *) printf -v hex '%02X' "'$c"; out+="%${hex: -2}" ;;
        esac
    done
    printf '%s' "$out"
}

remoteName=${1:-origin}
branch=`git rev-parse --abbrev-ref HEAD`
commit_subject=$(git log -1 --pretty=%s)
commit_body=$(git log -1 --pretty=%b)

remote=`git remote get-url --push "$remoteName" 2>/dev/null`
if [[ -z "$remote" ]]; then
    echo "error: no push URL for remote '$remoteName'"
    exit 1
fi

# Normalize SSH/HTTPS remote URLs to server + group/project.
# Handles: git@host:group/project.git  ssh://git@host:port/group/project
#          https://host/group/project(.git)  http://...  (optional .git)
path=${remote%.git}
case "$path" in
    *://*)                 # ssh:// https:// http://
        path=${path#*://}  # drop scheme
        path=${path#*@}    # drop optional user@
        server=${path%%/*} # server is up to first /
        path=${path#*/}    # remainder is group/project
        ;;
    *@*:*)                 # scp-like: git@host:group/project
        server=${path#*@}
        server=${server%%:*}
        path=${path#*:}    # remainder after host:
        ;;
    *)
        echo "error: unsupported remote '$remote'"
        exit 1
        ;;
esac
server=${server%%:*}       # strip any :port
group=${path%/*}           # everything up to last / (keeps GitLab subgroups)
project=${path##*/}        # last path segment

if [[ -z "$server" || -z "$group" || -z "$project" ]]; then
    echo "error: could not parse remote '$remote'"
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

title="$prefix $commit_subject"

if [[ "$server" == github.com ]]; then
    url="https://github.com/$group/$project/compare/$target...$branch?expand=1&title=$(urlencode "$title")&labels=$(urlencode "$labels")&body=$(urlencode "$commit_body")"
    echo "$url"
    open "$url"
else
    if [[ "$target" == master ]]; then
        open "https://$server/$group/$project/merge_requests/new?merge_request%5Bforce_remove_source_branch%5D=1&merge_request%5Bsource_branch%5D=$branch&merge_request%5B"
    else
        open "https://$server/$group/$project/merge_requests/new?merge_request%5Bforce_remove_source_branch%5D=1&merge_request%5Bsource_branch%5D=$branch&merge_request%5Btarget_branch%5D=$target"
    fi
fi