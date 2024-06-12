{lib, ...}:
with lib; rec {
  moduleLoadOptions = {...}: {
    options = {
      moduleLoad = mkOption {
        type = types.listOf (types.str);
        default = [];
      };
    };
  };

  moduleBlacklistOptions = {...}: {
    options = {
      blacklistedKernelModules = mkOption {
        type = types.listOf (types.str);
        default = [];
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

  getEnableKernelModuleForDevice = device: let
    enable = device.enable;
  in
    lib.optionals enable device.enableMethod.moduleLoad;

  getEnableKernelModules = devices: let
    deviceList = builtins.attrValues devices;
  in
    builtins.concatMap (value: (getEnableKernelModuleForDevice value)) deviceList;

  getDisableKernelModulesForDevice = device: let
    disable = !device.enable;
  in
    lib.optionals disable device.disableMethod.blacklistedKernelModules;

  getDisableKernelModules = devices: let
    deviceList = builtins.attrValues devices;
  in
    builtins.concatMap (value: (getDisableKernelModulesForDevice value)) deviceList;
}
