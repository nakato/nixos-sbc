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
      type = types.enum ["standard" "b"];
      description = mdDoc ''
        Hardware variant of the Orange Pi 5 board in use.

        The 5B is a minor revision on the 5 that adds eMMC storage, WiFi and
        bluetooth, but removes the PCIe2 M.2, Fan Header, and SPI flash.
      '';
    };
    # FIXME: This should probably be made generic somehow.
    ubootPackage = mkOption {
      default = sbcPkgs.ubootOrangePi5;
      type = types.package;
    };
  };

  config = let
    variantText = lib.optionalString (cfg.hardwareVariant == "b") "b";
  in {
    # TODO: Throw a warning about the standard variant being untested and
    # that sbc.board might not fully reflect it.

    sbc.enable = true;

    boot.kernelPackages = pkgs.linuxPackages_6_9;
    hardware.deviceTree = {
      kernelPackage = sbcPkgs.orangePi5bDTBs;
      filter = "rk3588s*orangepi*.dtb";
    };
    sbc.board.xunlong.opi5.ubootPackage = lib.mkIf (cfg.hardwareVariant == "b") sbcPkgs.ubootOrangePi5b;

    sbc.board = {
      vendor = "xunlong";
      model = "OrangePi5${variantText}";
      dtRoot = "xunlong,orangepi-5";

      # i2c0: CPU power management, no user function
      i2c.devices.i2c1 = {
        # i2c1m4 Pin 16/18
        # i2c1m2 Pin 12/15
        # Note: M2/M4 are mutually exclusive, it changes what pins i2c1 is on.
        status = "disabled";
        # FIXME: Enable methods
      };
      # i2c2: NPU power management, no user function
      i2c.devices.i2c3 = {
        # Pin 21/19
        status = "disabled";
        # FIXME: Enable Methods
      };
      i2c.devices.i2c5 = {
        # Pin 3/5
        status = "disabled";
        # FIXME: Enable Methods
      };
      # i2c6: HYM8563 RTC, no user function

      uart.devices.uart0 = {
        # Pins 8/10
        status = "disabled";
        deviceName = "ttyS0";
        console = false;
        # FIXME: Enable Methods
      };
      uart.devices.uart1 = {
        # Pins 3/5
        status = "disabled";
        deviceName = "ttyS1";
        console = false;
        # FIXME: Enable Methods
      };
      uart.devices.uart2 = {
        status = "okay";
        baud = 1500000;
        deviceName = "ttyS2";
        console = true;
        # FIXME: Disable Methods
      };
      uart.devices.uart3 = {
        # 19/21
        status = "disabled";
        deviceName = "ttyS3";
        console = false;
        # FIXME: Enable Methods
      };
      uart.devices.uart4 = {
        # 16/18
        status = "disabled";
        deviceName = "ttyS4";
        console = false;
        # FIXME: Enable Methods
      };

      rtc.devices.hym8563 = {
        status = "always";
        disableMethod.blacklistedKernelModules = ["rtc_hym8563"];
        # The RTC might be useful during reboots, but that means a reboot
        # behaves differently than a cold-boot, and that's not okay.
        # If the user solders a battery to the RTC1 and GND1 testpoints
        # near the chip, then this would be fine.
        enable = lib.mkDefault false;
      };
    };
  };
}
