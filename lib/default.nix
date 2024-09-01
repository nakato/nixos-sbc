{
  lib,
  nixpkgs,
  self,
}: rec {
  forSystems = systems: f: lib.genAttrs systems (system: f system);

  forAllSystems = forSystems (builtins.attrNames nixpkgs.legacyPackages);

  supportedBuildSystems = ["aarch64-linux" "riscv64-linux" "x86_64-linux"];
  forSupportedBuildSystems = forSystems supportedBuildSystems;

  supportedHostSystems = ["aarch64-linux" "riscv64-linux"];
  forSupportedHostSystems = forSystems supportedHostSystems;

  builders = let
    # Return true if attr exists and is a derivation.
    hasAttrDrv = as: attr: (builtins.hasAttr attr as) && lib.isDerivation as.${attr};

    # If attrSet is not a derivation and has kernel and systemtap as derivations it's probably a kernelPackages attrSet
    isKernelPackageSet = as: !(lib.isDerivation as) && (hasAttrDrv as "kernel") && (hasAttrDrv as "systemtap");

    # Resonable list of kernel-specific packages to compile and cache.
    allowedKernPackages = ["kernel" "systemtap" "jool" "perf"];
    # Take an attrSet, determine if it is a duck, and if it is filter it to the reduced set of kernel packages to build for cache.
    filterKernelPackageSet = as:
      if (isKernelPackageSet as)
      then
        (
          if as.kernel.configfile.autoModules
          then {} # Never build the full distro-style kernels.
          else lib.filterAttrs (k: _: builtins.elem k allowedKernPackages) as
        )
      else as;

    # Chain the filters here
    applySetFilters = as: (filterKernelPackageSet as);

    recursiveAttributeFilter = pkgs:
      builtins.mapAttrs (
        k: v:
          if lib.isDerivation v
          then v # Filtering derivations is handled after flattened
          else applySetFilters v
      )
      pkgs;

    flattenDerivations = pkgs:
      builtins.foldl' (acc: elem:
        (
          if (lib.isDerivation pkgs.${elem})
          then {"${elem}" = pkgs."${elem}";}
          else lib.concatMapAttrs (childName: v: {${elem + "__" + childName} = v;}) pkgs."${elem}"
        )
        // acc) {} (builtins.attrNames pkgs);

    # libintl is null on glibc platforms, so we have to get rid of it ourselves.
    # buildInputs may also have direct paths into nix store.
    filterBuildInputs = l: builtins.filter (v: (!(builtins.isNull v || builtins.isPath v))) l;
    allBuildInputs' = pkg:
      builtins.genericClosure {
        startSet = [
          {
            key = "${pkg.name}";
            drv = pkg;
          }
        ];
        operator = item:
        # If this starts blowing up change key to "(builtins.trace "${item.drv.name}" "${drv.name}") to figure out where it's coming from.
          builtins.map (drv: {
            key = "${drv.name}";
            drv = drv;
          }) (filterBuildInputs item.drv.drvAttrs.buildInputs);
      };
    # Recursively get all derivations referenced by buildInputs for a derivation.
    allBuildInputs = pkg: builtins.map (v: v.drv) (allBuildInputs' pkg);

    # Get the license or return unfree if it's missing.
    licenseOrUnfree = pkg:
      if builtins.hasAttr "license" pkg.meta
      then pkg.meta.license
      else builtins.trace "Missing meta.license on ${pkg.name}" lib.licenses.unfree;
    isLicenseUnfree = lic:
      if builtins.isList lic
      then builtins.any isLicenseUnfree lic
      else (!lic.free);
    hasUnfree = pkg: !(builtins.any (f: (isLicenseUnfree (licenseOrUnfree f))) (allBuildInputs pkg));

    applyDrvFilters = pkg: hasUnfree pkg;

    filterDerivations = pkgs: lib.filterAttrs (_: v: applyDrvFilters v) pkgs;

    prepareFlattenedPackageSet = pkgs: filterDerivations (flattenDerivations (recursiveAttributeFilter pkgs));
  in {
    buildTargets = builtins.mapAttrs (arch: pkgs: prepareFlattenedPackageSet pkgs) self.packages;
  };
}
