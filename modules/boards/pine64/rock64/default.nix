{
  config,
  lib,
  sbcLibPath,
  sbcPkgs,
  ...
}: let
  cfg = config.sbc.board.pine64.rock64;
in {
  imports = [
    ./sd-image.nix
  ];

  options.sbc.board.pine64.rock64 = with lib; {
    hardwareRevision = mkOption {
      type = types.enum ["v2" "v3"];
      description = mdDoc ''
        Hardware revision of the Rock64 board in use.

        This must be set as a safe default cannot be taken between the two.
        v2 boards need special consideration to prevent memory corruption.
      '';
    };
  };

  config = {
    sbc.enable = true;

    sbc.board = {
      vendor = "Pine64";
      model = "Rock64";
      dtRoot = "rockchip,rk3328";

      i2c.devices.i2c0 = {
        status = "disabled";
        enableMethod.dtOverlay.enable = true;
      };

      uart.devices.uart2 = {
        status = "okay";
        baud = 1500000;
        deviceName = "ttyS2";
        console = true;
      };

      rtc.devices.rk808 = {
        status = "always";
        disableMethod.blacklistedKernelModules = ["rtc_rk808"];
        enable = lib.mkDefault false;
      };
    };
  };
}
