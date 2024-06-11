{
  config,
  lib,
  pkgs,
  sbcLibPath,
  ...
}:
with lib; let
  cfg = config.sbc.board.i2c;

  i2cDevice = ./device.nix;

  findTargetsToEnable = devices: lib.filterAttrs (t: d: d.enable && d.status == "disabled") devices;
  findTargetsToDisable = devices: lib.filterAttrs (t: d: (!d.enable) && d.status != "disabled") devices;
  targetAttrsetToList = devices: lib.attrValues (lib.mapAttrs (t: d: {target = t;} // d) devices);

  removeDisabledEnableDTTargets = devices: lib.filter (d: d.enableMethod.dtOverlay.enable) devices;
  removeNullEnableModuleTargets = devices: lib.filter (d: d.enableMethod.moduleLoad != null) devices;

  removeDisabledDisableDTTargets = devices: lib.filter (d: d.disableMethod.dtOverlay.enable) devices;
  removeNullDisableModuleTargets = devices: lib.filter (d: d.disableMethod.blacklistedKernelModules != null) devices;
in {
  options = {
    sbc.board.i2c.devices = mkOption {
      type = types.attrsOf (types.submoduleWith {
        modules = [i2cDevice];
        specialArgs = {
          inherit sbcLibPath;
          globalConfig = config;
        };
      });
    };
  };

  config = let
    enableTargets = targetAttrsetToList (findTargetsToEnable cfg.devices);
    enableDTTargets = removeDisabledEnableDTTargets enableTargets;
    enableModuleTargets = removeNullEnableModuleTargets enableTargets;

    disableTargets = targetAttrsetToList (findTargetsToDisable cfg.devices);
    disableDTTargets = removeDisabledDisableDTTargets disableTargets;
    disableModuleTargets = removeNullDisableModuleTargets disableTargets;

    enableDTO = builtins.map (d: d.enableMethod.dtOverlay.dtOverlay) enableDTTargets;
    disableDTO = builtins.map (d: d.disableMethod.dtOverlay.dtOverlay) disableDTTargets;
  in {
    hardware.deviceTree.overlays = enableDTO ++ disableDTO;
    boot.initrd.kernelModules = lib.flatten (builtins.map (d: d.enableMethod.moduleLoad) enableModuleTargets);
    boot.blacklistedKernelModules = lib.flatten (builtins.map (d: d.disableMethod.blacklistedKernelModules) disableModuleTargets);
  };
}
