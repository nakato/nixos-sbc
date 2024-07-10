{
  config,
  lib,
  pkgs,
  ...
}: let
  sbcCiScript = let
    path = with pkgs;
      lib.makeBinPath [
        coreutils-full
        nettools
        cachix
        gnugrep
        git
        jq
        nix
      ];
  in
    pkgs.writeShellScriptBin "nixos-sbc-ci-run" ''
      export PATH="${path}"
      export HOME="$RUNTIME_DIRECTORY"
      CACHIX_REPO="nixos-sbc"

      set -euo pipefail

      git config --global user.email "sbc-ci@$(hostname)"
      git config --global user.name "SBC-CI"

      cd "$RUNTIME_DIRECTORY"
      git clone "https://''${GITHUB_AUTH_KEY}@github.com/nakato/nixos-sbc.git"
      echo "Sucesfully cloned repo"
      cd nixos-sbc
      nix flake lock --update-input nixpkgs
      git status --porcelain | grep " M flake.lock"
      if [[ $? -ne 0 ]]; then
        echo "No changes to lockfile, nothing to do, exiting"
        exit 0
      fi

      git add flake.lock
      git commit -m "flake: update nixpkgs"

      TARGETS=($(nix eval --raw .#_lib.builders.buildTargets.aarch64-linux --apply 'f: builtins.concatStringsSep " " (builtins.attrNames f)'))

      for TARGET in ''${TARGETS[@]}; do
        echo "Building target: $TARGET"
        nix build --json ".#_lib.builders.buildTargets.aarch64-linux.''${TARGET}" | jq -r '.[].outputs[]' >> "''${RUNTIME_DIRECTORY}/cache_targets"
      done

      echo "Pushing to cachix"
      cat "''${RUNTIME_DIRECTORY}/cache_targets" | cachix push "$CACHIX_REPO"

      # Builds succeeded, and caches are primed, push the new lock.
      git push
    '';
in {
  systemd.timers."nixos-sbc-ci" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Unit = "nixos-sbc-ci.service";
    };
  };

  systemd.services."nixos-sbc-ci" = {
    script = ''
      ${sbcCiScript}/bin/nixos-sbc-ci-run
    '';
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      EnvironmentFile = config.age.secrets."sbc-ci-env.age".path;
      RuntimeDirectory = "sbc-ci-env";
    };
  };
}
