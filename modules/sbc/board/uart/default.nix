{
  config,
  lib,
  pkgs,
  sbcLibPath,
  ...
}:
with lib; let
  cfg = config.sbc.board.uart;

  inherit (pkgs.callPackage (sbcLibPath + "/options/device") {inherit sbcLibPath;}) baseDevice dtOverlayMethods moduleMethods getDTOverlays getEnableKernelModules getDisableKernelModules;

  uartDevice = {
    config,
    lib,
    ...
  }:
    with lib; {
      options = {
        deviceName = mkOption {
          type = types.str;
          description = mdDoc "Name of UART device in Linux";
        };

        baud = mkOption {
          type = types.int;
          description = mdDoc "Default baud-rate of the hardware, used by software";
        };

        console = mkOption {
          type = types.bool;
          description = mdDoc "If true, device will be configured as a console during boot";
        };
      };
    };

  toDeviceList = builtins.attrValues;
  consoleDevices = builtins.filter (device: device.console);
  consoleToParams = builtins.map (device: "console=${device.deviceName},${builtins.toString device.baud}");
  consoleParams = devices: consoleToParams (consoleDevices (toDeviceList devices));
in {
  options = {
    sbc.board.uart.devices = mkOption {
      type = types.attrsOf (types.submoduleWith {
        modules = [baseDevice dtOverlayMethods moduleMethods uartDevice];
        specialArgs = {
          inherit sbcLibPath pkgs;
          globalConfig = config;
        };
      });
      default = {};
    };
  };

  config = lib.mkIf config.sbc.enable {
    assertions = [
      {
        assertion = builtins.any (device: device.console -> device.enable) (builtins.attrValues cfg.devices);
        message = ''
          Console requested on UART device that is disabled.  Disable console or enable device.
        '';
      }
    ];

    hardware.deviceTree.overlays = getDTOverlays cfg.devices;
    boot.initrd.kernelModules = getEnableKernelModules cfg.devices;
    boot.blacklistedKernelModules = getDisableKernelModules cfg.devices;

    boot.kernelParams = consoleParams cfg.devices;
  };
}
