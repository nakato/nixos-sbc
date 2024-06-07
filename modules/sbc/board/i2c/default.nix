{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.sbc.board.i2c;

  i2cDevice = import ./device.nix;

  findTargetsToEnable = devices: lib.filterAttrs (t: d: d.enable && d.status == "disabled") devices;
  findTargetsToDisable = devices: lib.filterAttrs (t: d: (!d.enable) && d.status != "disabled") devices;
  targetAttrsetToList = devices: lib.attrValues (lib.mapAttrs (t: d: {target = t;} // d) devices);

  removeNullEnableDTTargets = devices: lib.filter (d: d.enableMethod.dtOverlay != null) devices;
  removeNullEnableModuleTargets = devices: lib.filter (d: d.enableMethod.moduleLoad != null) devices;

  removeNullDisableDTTargets = devices: lib.filter (d: d.disableMethod.dtOverlay != null) devices;
  removeNullDisableModuleTargets = devices: lib.filter (d: d.disableMethod.blacklistedKernelModules != null) devices;
in {
  options = {
    sbc.board.i2c.devices = mkOption {
      type = types.attrsOf (types.submodule i2cDevice);
      default = {};
    };
  };

  config = let
    enableTargets = targetAttrsetToList (findTargetsToEnable cfg.devices);
    enableDTTargets = removeNullEnableDTTargets enableTargets;
    enableModuleTargets = removeNullEnableModuleTargets enableTargets;

    disableTargets = targetAttrsetToList (findTargetsToDisable cfg.devices);
    disableDTTargets = removeNullDisableDTTargets disableTargets;
    disableModuleTargets = removeNullDisableModuleTargets disableTargets;

    enableDTO = builtins.map (d: (import d.enableMethod.dtOverlay) "i2c-${d.target}" "&${d.target}" config.sbc.board.dtRoot) enableDTTargets;
    disableDTO = builtins.map (d: (import d.disableMethod.dtOverlay) "i2c-${d.target}" "&${d.target}" config.sbc.board.dtRoot) disableDTTargets;
  in {
    hardware.deviceTree.overlays = enableDTO ++ disableDTO;
    boot.initrd.kernelModules = lib.flatten (builtins.map (d: d.enableMethod.moduleLoad) enableModuleTargets);
    boot.blacklistedKernelModules = lib.flatten (builtins.map (d: d.disableMethod.blacklistedKernelModules) disableModuleTargets);
  };
}
