{lib, ...}:
with lib; rec {
  moduleLoadOptions = {...}: {
    options = {
      moduleLoad = mkOption {
        type = types.nullOr (types.listOf (types.str));
        default = null;
      };
    };
  };

  moduleBlacklistOptions = {...}: {
    options = {
      blacklistedKernelModules = mkOption {
        type = types.nullOr (types.listOf (types.str));
        default = null;
      };
    };
  };

  moduleMethods = {...}: {
    options = {
      enableMethod = mkOption {
        type = types.submoduleWith {
          modules = [moduleLoadOptions];
        };
      };

      disableMethod = mkOption {
        type = types.submoduleWith {
          modules = [moduleBlacklistOptions];
        };
      };
    };
  };
}
