{config, lib, ...}:
with lib;
let
  enableOption = {config, globalConfig, ...}: {
    options = {
      dtOverlay = mkOption {
        # this made to be the imported function instead of a path?
        type = types.path;
      };

      moduleLoad = mkOption {
        type = types.nullOr (types.listOf (types.str));
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
  };

  config = {
    enable = mkOptionDefault (config.status != "disabled");
  };
}
