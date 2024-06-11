{...}: {
  moduleLoadOptions = {lib, ...}:
    with lib; {
      options = {
        moduleLoad = mkOption {
          type = types.nullOr (types.listOf (types.str));
          default = null;
        };
      };
    };

  moduleBlacklistOptions = {lib, ...}:
    with lib; {
      options = {
        blacklistedKernelModules = mkOption {
          type = types.nullOr (types.listOf (types.str));
          default = null;
        };
      };
    };
}
