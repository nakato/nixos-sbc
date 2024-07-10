{
  lib,
  nixpkgs,
  self,
}: rec {
  forSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f system);

  forAllSystems = forSystems (builtins.attrNames nixpkgs.legacyPackages);

  supportedSystems = ["aarch64-linux" "riscv64-linux"];
  forSupportedSystems = forSystems supportedSystems;

  bootstrapSystem = {
    modules,
    system ? "aarch64-linux",
    ...
  } @ config:
    nixpkgs.lib.nixosSystem (
      config
      // {
        inherit system;
        modules =
          modules
          ++ [
            self.nixosModules.default
            {
              sbc.bootstrap.initialBootstrapImage = true;
              sbc.version = "0.2";
            }
          ];
      }
    );

  builders = rec {
    flattenNested = name: pkgs: lib.concatMapAttrs (pName: drv: {${name + "__" + pName} = drv;}) pkgs;
    filterSkipBuildCache = pkgs: lib.filterAttrs (n: v: (v.meta ? skipBuildCache -> !(v.meta.skipBuildCache))) pkgs;
    filterKernelPackages = pkgs:
      if (pkgs ? isZen)
      then {inherit (pkgs) kernel;}
      else pkgs;

    flattenDerivations' = pkgs:
      builtins.foldl' (acc: elem:
        (
          if (lib.isDerivation pkgs.${elem})
          then {"${elem}" = pkgs."${elem}";}
          else (flattenNested elem (flattenDerivations pkgs."${elem}"))
        )
        // acc) {} (builtins.attrNames pkgs);
    flattenDerivations = pkgs: flattenDerivations' (filterKernelPackages pkgs);
    filterBuildTargets = pkgs: filterSkipBuildCache (flattenDerivations pkgs);
    buildTargets = builtins.mapAttrs (arch: pkgs: filterBuildTargets pkgs) self.packages;
  };
}
