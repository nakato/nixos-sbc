{
  name,
  globalConfig,
  config,
  lib,
  sbcLibPath,
  ...
}:
with lib; let
  enableOption = {
    config,
    globalConfig,
    ...
  }: {
    options = {
      dtOverlay = mkOption {
        type = types.submoduleWith {
          modules = [(sbcLibPath + "/device-tree/simple-overlay.nix")];
          specialArgs = {
            inherit globalConfig;
            target = name;
            status = "okay";
          };
        };
        default = {};
      };

      moduleLoad = mkOption {
        type = types.nullOr (types.listOf (types.str));
        default = null;
      };
    };
  };

  disableOption = {
    config,
    globalConfig,
    ...
  }: {
    options = {
      dtOverlay = mkOption {
        type = types.submoduleWith {
          modules = [(sbcLibPath + "/device-tree/simple-overlay.nix")];
          specialArgs = {
            inherit globalConfig;
            target = name;
            status = "disabled";
          };
        };
        default = {};
      };

      blacklistedKernelModules = mkOption {
        type = types.nullOr (types.listOf (types.str));
        default = null;
      };
    };
  };
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
        modules = [enableOption];
        specialArgs = {globalConfig = globalConfig;};
      };
      default = {};
    };

    disableMethod = mkOption {
      type = types.submoduleWith {
        modules = [disableOption];
        specialArgs = {globalConfig = globalConfig;};
      };
      default = {};
    };
  };

  config = {
    enable = mkOptionDefault (config.status != "disabled");
  };
}
