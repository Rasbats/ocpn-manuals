#!/bin/bash

#
# Some pidgin git submodules mockup. Allows all included plugin
# directories to be represented by their url and commit.
#
# Arguments: an operation, mandatory, one of:
#
#   - restore: fetches and checkout all repos listed in statefile
#   - save: Save state of all plugin repos in statefile
#   - update: Update all plugin repos to latest version (does not save!).
#
# Files:
#   sources.state: directory, url and commit for plugin sources.
#


here=$(readlink -fn $(dirname $0))
statefile="$here/sources.state"
test -d $here/sources || mkdir $here/sources

cleanup_clone() {
    for f in *; do
        case $f in
            manual|antora.yml|modules) true ;;
            *) rm -rf $f
        esac
    done
}

git_clone() {
    vers=$(git --version)
    if [[ "$vers" == *2.[345][0-9].* ]]; then   # > 2.30
        echo $1
        git submodule add $1 $2
        git commit -m "Added"
        git push
    fi
    cd ..
}

cd $here/sources
git config advice.detachedHead false
case "$1" in
    restore) 
        while true; do
            read dir url commit || exit 0
            cd $here/sources
            git remote rm $url
            git submodule add $url $dir
			git commit -m "Added"
            git push
            cd ..
        done < $statefile
        ;;

    update)
        for dir in $(find . -maxdepth 1 -mindepth 1 -type d); do
            cd $dir
            echo -n "$dir: "
            git remote update origin
            head=$(git rev-parse refs/remotes/origin/HEAD)
            git checkout $head
            cleanup_clone
            cd ..
        done
        ;;

    save)
        rm -f $statefile
        for dir in $(find . -maxdepth 1 -mindepth 1 -type d); do
            cd $dir
            url=$(git remote show origin | awk '/Fetch URL/ {print $3}')
            echo $dir $url $(git rev-parse HEAD) >> $statefile
            cd ..
        done
        ;;

    *) echo 'Usage: $0: <save | restore | update>'
        ;;
esac
