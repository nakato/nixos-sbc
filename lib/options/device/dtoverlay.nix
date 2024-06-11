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
}
