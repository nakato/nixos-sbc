{
  name,
  globalConfig,
  config,
  lib,
  pkgs,
  sbcLibPath,
  ...
}:
with lib; let
  inherit (pkgs.callPackage (sbcLibPath + "/options/device/dtoverlay.nix") {inherit sbcLibPath;}) dtOverlayOptions;
  inherit (pkgs.callPackage (sbcLibPath + "/options/device/modules.nix") {}) moduleLoadOptions moduleBlacklistOptions;
in {
  options = {
    dtTarget = mkOption {
      type = types.str;
      default = name;
    };

    status = mkOption {
      type = types.enum ["disabled" "okay" "always"];
      description = mdDoc "Status of hardware in DT";
    };

    enable = mkOption {
      type = types.bool;
      description = mdDoc "Disable or enable hardware in device tree";
    };

    enableMethod = mkOption {
      type = types.submoduleWith {
        modules = [dtOverlayOptions moduleLoadOptions];
        specialArgs = {
          inherit name;
          globalConfig = globalConfig;
          dtStatus = "okay";
        };
      };
      default = {};
    };

    disableMethod = mkOption {
      type = types.submoduleWith {
        modules = [dtOverlayOptions moduleBlacklistOptions];
        specialArgs = {
          inherit name;
          globalConfig = globalConfig;
          status = "disabled";
        };
      };
      default = {};
    };
  };

  config = {
    enable = mkOptionDefault (config.status != "disabled");
  };
}
