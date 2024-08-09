#!/usr/bin/env bash

set -euo pipefail

SCRIPT_PATH="$(readlink -f $0)"
SCRIPT_DIR="$(dirname ${SCRIPT_PATH})"

export GIT_AUTHOR_EMAIL="sbc-ci@$(hostname)"
export GIT_AUTHOR_NAME="SBC-CI"

PREV_ATTRSET="$(nix eval '.#_lib.builders.buildTargets.aarch64-linux' --apply 'drv: builtins.mapAttrs (k: v: {prev = v.drvPath;}) drv')"

nix flake update --commit-lock-file

NEXT_ATTRSET="$(nix eval '.#_lib.builders.buildTargets.aarch64-linux' --apply 'drv: builtins.mapAttrs (k: v: {next = v.drvPath;}) drv')"

NEEDS_REFRESH="$(nix eval --impure --expr "import ./compareDrvs.nix ${PREV_ATTRSET} ${NEXT_ATTRSET}" --apply "as: as.needsRefresh")"

if [[ $NEEDS_REFRESH = false ]]; then
	echo "No derivations need refreshed, not updating lockfile and not rebuilding"
	exit 0
fi

echo "Derivations need to be built and pushed to cache"

TARGETS=($(nix eval --raw .#_lib.builders.buildTargets.aarch64-linux --apply 'f: builtins.concatStringsSep " " (builtins.attrNames f)'))

for TARGET in ${TARGETS[@]}; do
  echo "Building target: $TARGET"
  nix build ".#_lib.builders.buildTargets.aarch64-linux.${TARGET}"
done

for TARGET in ${TARGETS[@]}; do
  echo "Pushing artifacts for: $TARGET"
  nix eval --json ".#_lib.builders.buildTargets.aarch64-linux.${TARGET}" --apply 'drv: builtins.map (n: drv.${n}) drv.outputs' | cachix push "$CACHIX_REPO"
done

git push
