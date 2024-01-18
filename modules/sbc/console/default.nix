{ config
, lib
, options
, pkgs
, ...
}:
let
  cfg = config.sbc.console;
  uart = import ../../../lib/board/spec/uart.nix;
in
{
  options.sbc.console = with lib; {
    devices = mkOption {
      type = types.listOf (types.submodule uart);
      description = lib.mdDoc ''
        List of UART devices to request logging to.
      '';
    };
  };

  config = lib.mkIf config.sbc.enable {
    assertions = [
      {
        assertion = builtins.any (attr: !attr.enable) cfg.devices;
        message = ''
          A UART device disabled in DT cannot be used as a console paramater.
          Enable the device, or override the sbc.console.devices list.
        '';
      }
    ];

    boot.kernelParams = builtins.map (attrs: "console=${attrs.deviceName},${builtins.toString attrs.baud}" ) cfg.devices;
  };
}
