{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.sbc.board.uart;

  uartDevice = import ./device.nix;

  toDeviceList = builtins.attrValues;
  consoleDevices = builtins.filter (device: device.console);
  consoleToParams = builtins.map (device: "console=${device.deviceName},${builtins.toString device.baud}");
  consoleParams = devices: consoleToParams (consoleDevices (toDeviceList devices));
in {
  options = {
    sbc.board.uart.devices = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule uartDevice));
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

    boot.kernelParams = consoleParams cfg.devices;
  };
}
