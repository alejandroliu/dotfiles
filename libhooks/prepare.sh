#!/bin/sh
#
# Prepare hooks...
#
libhookdir=$(dirname $(readlink -f $0))
gitdir=$(dirname $libhookdir)

cp -av $libhookdir/pre-commit $gitdir/.git/hooks/pre-commit
cp -av $libhookdir/post-checkout $gitdir/.git/hooks/post-checkout
cp -av $libhookdir/post-checkout $gitdir/.git/hooks/post-merge

# make sure post hook is run!
( cd $gidir ; sh .git/hooks/post-checkout )
