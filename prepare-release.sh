#!/usr/bin/env nix-shell
#!nix-shell -p git -p nix -p gitAndTools.hub -i bash

set -eux -o pipefail

version=$(nix eval --raw '(import ./nix/release.nix {}).tarball.version')
git tag -d "$version" || true
git tag "$version"
branch="release-${version}"
git branch -D "$branch" || true
git checkout -b "$branch"
git push origin +"$branch"
hub pull-request -b Mic92:master -m "nix ${version}"
git checkout master
