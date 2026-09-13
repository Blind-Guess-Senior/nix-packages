#!/usr/bin/env bash
#
# Update one package and report what the workflow should do with it.
#
#     ci/update-package.sh movie-pool
#     ci/update-package.sh python3Packages.python-steamgriddb
#
# The argument names a path inside the flake's `legacyPackages` -- the same
# string the workflow's matrix carries. Run it from a clean checkout of this
# repository: the package file is edited in place and the change is left
# uncommitted for the pull-request action to commit, so a tree that already had
# changes would end up in the pull request.
#
# Reports, as GitHub step outputs when $GITHUB_OUTPUT is set and on stdout:
#
#     changed   whether nix-update modified anything
#     version   the version after the update
#     summary   "old -> new (class)", for the pull request title
#     merge     whether passthru.updatePolicy.autoMerge covers this version class

set -euo pipefail

package=${1:?usage: update-package.sh <path-in-flake>}

# "Something changed" further down means "the tree is dirty", which only
# describes this package when nothing else was dirty to begin with.
if [[ -n $(git status --porcelain) ]]; then
  echo "error: the working tree already has changes; commit or stash them first" >&2
  exit 1
fi

report() {
  printf '%s\n' "$@"
  if [[ -n ${GITHUB_OUTPUT:-} ]]; then
    printf '%s\n' "$@" >> "$GITHUB_OUTPUT"
  fi
}

# Same rule the packages are written against: only major.minor.patch counts.
# Extra components (1.2.3.4) fold into patch, and a version without three
# numeric components (a date, say) is "unknown" and never merged automatically.
classify() {
  local old="${1#v}" new="${2#v}"
  [[ $old =~ ^([0-9]+)\.([0-9]+)\. ]] || { echo unknown; return; }
  local old_major=${BASH_REMATCH[1]} old_minor=${BASH_REMATCH[2]}
  [[ $new =~ ^([0-9]+)\.([0-9]+)\. ]] || { echo unknown; return; }
  local new_major=${BASH_REMATCH[1]} new_minor=${BASH_REMATCH[2]}
  if   [[ $old_major != "$new_major" ]]; then echo major
  elif [[ $old_minor != "$new_minor" ]]; then echo minor
  else echo patch
  fi
}

# Everything is read through the flake, and nix-update comes from the nixpkgs the
# flake is locked to, so a floating nixpkgs cannot change what the bot does.
attr="legacyPackages.$(nix eval --raw --impure --expr builtins.currentSystem).$package"
eval_pkg() { nix eval --raw ".#$attr" --apply "$1"; }

old=$(eval_pkg 'd: d.version')
policy=$(eval_pkg 'd: builtins.concatStringsSep "," (d.updatePolicy.autoMerge or [])')

nix shell "github:NixOS/nixpkgs/$(jq -r .nodes.nixpkgs.locked.rev flake.lock)#nix-update" \
  -c nix-update -F --build "$attr"

# --build makes nix-update stop before committing when the bump does not build,
# which leaves a half-written file behind. That is fine here: the job fails right
# after, and the tree dies with the runner.
if git diff --quiet; then
  echo "already up to date"
  report changed=false
  exit 0
fi

new=$(eval_pkg 'd: d.version')
class=$(classify "$old" "$new")

merge=false
if [[ $class != unknown && ",$policy," == *",$class,"* ]]; then
  merge=true
fi

echo "$old -> $new ($class), auto-merge: $merge"
report changed=true "version=$new" "summary=$old -> $new ($class)" "merge=$merge"
