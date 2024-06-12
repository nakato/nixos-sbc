{
  lib,
  sbcLibPath,
  ...
}:
with lib; rec {
  dtOverlayOptions = {
    dtStatus,
    globalConfig,
    target,
    ...
  }: {
    options = {
      dtOverlay = mkOption {
        type = types.submoduleWith {
          modules = [(sbcLibPath + "/device-tree/simple-overlay.nix")];
          specialArgs = {
            inherit globalConfig target;
            status = dtStatus;
          };
        };
        default = {};
      };
    };
  };

  dtOverlayMethods = {
    globalConfig,
    name,
    ...
  }: {
    options = {
      enableMethod = mkOption {
        type = types.submoduleWith {
          modules = [dtOverlayOptions];
          specialArgs = {
            inherit globalConfig;
            target = name;
            dtStatus = "okay";
          };
        };
        default = {};
      };
      disableMethod = mkOption {
        type = types.submoduleWith {
          modules = [dtOverlayOptions];
          specialArgs = {
            inherit globalConfig;
            target = name;
            dtStatus = "disabled";
          };
        };
        default = {};
      };
    };
  };

  getDTOverlay = dtConfig: let
    enable = dtConfig.enable;
    enableDts = lib.optionals (enable && dtConfig.enableMethod.dtOverlay.enable) [dtConfig.enableMethod.dtOverlay.dtOverlay];
    disableDts = lib.optionals (!enable && dtConfig.disableMethod.dtOverlay.enable) [dtConfig.disableMethod.dtOverlay.dtOverlay];
  in
    enableDts ++ disableDts;

  getDTOverlays = devices: let
    deviceList = builtins.attrValues devices;
  in
    builtins.concatMap (value: (getDTOverlay value)) deviceList;
}
