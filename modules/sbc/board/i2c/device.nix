{config, lib, ...}:
with lib;
let
  enableOption = {config, globalConfig, ...}: {
    options = {
      dtOverlay = mkOption {
        # this made to be the imported function instead of a path?
        type = types.nullOr types.path;
        default = null;
      };

      moduleLoad = mkOption {
        type = types.nullOr (types.listOf (types.str));
        default = null;
      };
    };
  };

  disableOption = {config, globalConfig, ...}: {
    options = {
      dtOverlay = mkOption {
        # this made to be the imported function instead of a path?
        type = types.nullOr types.path;
        default = null;
      };

      blacklistedKernelModules = mkOption {
        type = types.nullOr (types.listOf (types.str));
        default = null;
      };
    };
  };
in
{
  options = {
    status = mkOption {
      type = types.enum [ "disabled" "okay" "always" ];
      description = mdDoc "Status of hardware in DT";
    };

    enable = mkOption {
      type = types.bool;
      description = mdDoc "Disable or enable hardware in device tree";
    };

    enableMethod = mkOption {
      type = types.nullOr (types.submoduleWith { modules = [ enableOption ]; });
    };

    disableMethod = mkOption {
      type = types.nullOr (types.submoduleWith { modules = [ disableOption ]; });
    };
  };

  config = {
    enable = mkOptionDefault (config.status != "disabled");
  };
}
