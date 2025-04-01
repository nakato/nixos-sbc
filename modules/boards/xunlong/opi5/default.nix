{
  config,
  lib,
  pkgs,
  sbcPkgs,
  ...
}: let
  cfg = config.sbc.board.xunlong.opi5;
in {
  imports = [
    ./sd-image.nix
  ];

  options.sbc.board.xunlong.opi5 = with lib; {
    hardwareVariant = mkOption {
      type = types.enum ["standard" "b" "max"];
      description = mdDoc ''
        Hardware variant of the Orange Pi 5 board in use.

        The 5B is a minor revision on the 5 that adds eMMC storage, WiFi and
        bluetooth, but removes the PCIe2 M.2, Fan Header, and SPI flash.

        The Max is a version with a non-'s' variant of the SoC.
      '';
    };
    # FIXME: This should probably be made generic somehow.
    ubootPackage = mkOption {
      default = sbcPkgs.ubootOrangePi5;
      type = types.package;
    };
  };

  config = let
    variantText = {
      "standard" = "";
      "b" = "b";
      "max" = "max";
    }."${cfg.hardwareVariant}";
  in {
    # TODO: Throw a warning about the standard variant being untested and
    # that sbc.board might not fully reflect it.

    sbc.enable = true;

    boot.kernelPackages = pkgs.linuxPackages_6_14;
    hardware.deviceTree = {
      filter = "rk3588*orangepi*.dtb";
    };
    sbc.board.xunlong.opi5.ubootPackage = {
      "standard" = sbcPkgs.ubootOrangePi5;
      "b" = sbcPkgs.ubootOrangePi5b;
      "max" = sbcPkgs.ubootOrangePi5Max;
    }."${cfg.hardwareVariant}";

    # GPU requres firmware
    hardware.enableRedistributableFirmware = true;

    sbc.board = {
      vendor = "xunlong";
      model = "OrangePi5${variantText}";
      dtRoot = "xunlong,orangepi-5";

      # FIXME: For initial testing, just drop all the device options, it can stay default.

      uart.devices.uart2 = {
        status = "okay";
        baud = 1500000;
        deviceName = "ttyS2";
        console = true;
        disableMethod.dtOverlay.enable = true;
      };
    };
  };
}
