#!/usr/bin/env bash

set -x
PATCHES=$(find ${PWD} -name "*.patch")
echo $PATCHES
pushd /opt/src/CPython
  rm -rf .git/rebase-apply
  git checkout v3.6.9
  git reset --hard
  rm *.patch
  git rebase --abort
  git am -3 ${PATCHES}
  git format-patch -19
popd
git rm -f ${PATCHES}
mv /opt/src/CPython/*.patch .
