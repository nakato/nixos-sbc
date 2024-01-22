{config, lib, ...}: with lib;
let
  cfg = config.sbc.board.i2c;

  i2cDevice = import ./device.nix;

  findTargetsToEnable = devices: lib.filterAttrs (t: d: d.enable && d.status == "disabled") devices;
  targetAttrsetToList = devices: lib.attrValues (lib.mapAttrs (t: d: { target = t; } // d) devices);

  removeNullDTTargets = devices: lib.filter (d: d.enableMethod.dtOverlay != null) devices;
  removeNullModuleTargets = devices: lib.filter (d: d.enableMethod.moduleLoad != null) devices;
in
{
  options = {
    sbc.board.i2c.devices = mkOption {
      type = types.attrsOf (types.submodule i2cDevice);
      default = {};
    };
  };

  config =
    let
      enableTargets = targetAttrsetToList (findTargetsToEnable cfg.devices);
      dtTargets = removeNullDTTargets enableTargets;
      moduleTargets = removeNullModuleTargets enableTargets;
    in
  {
    hardware.deviceTree.overlays = builtins.map (d: (import d.enableMethod.dtOverlay) "i2c-${d.target}" "&${d.target}" config.sbc.board.dtRoot) dtTargets;
    boot.initrd.kernelModules = lib.flatten (builtins.map (d: d.enableMethod.moduleLoad) moduleTargets);
  };
}
