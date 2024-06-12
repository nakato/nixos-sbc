{
  config,
  lib,
  pkgs,
  sbcLibPath,
  ...
}:
with lib; let
  cfg = config.sbc.board.wifi;

  inherit (pkgs.callPackage (sbcLibPath + "/options/device") {inherit sbcLibPath;}) baseDevice dtOverlayMethods moduleMethods getDTOverlays getEnableKernelModules getDisableKernelModules;
in {
  options = {
    sbc.board.wifi.devices = mkOption {
      type = types.attrsOf (types.submoduleWith {
        modules = [baseDevice dtOverlayMethods moduleMethods];
        specialArgs = {
          inherit sbcLibPath pkgs;
          globalConfig = config;
        };
      });
      default = {};
    };
  };

  config = {
    hardware.deviceTree.overlays = getDTOverlays cfg.devices;
    boot.initrd.kernelModules = getEnableKernelModules cfg.devices;
    boot.blacklistedKernelModules = getDisableKernelModules cfg.devices;
  };
}
