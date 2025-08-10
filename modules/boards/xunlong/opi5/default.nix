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

    # This can be removed once linux_default >= 6.14
    boot.kernelPackages = pkgs.linuxPackages_6_16;
    hardware.deviceTree = {
      filter = "rk3588s*orangepi*.dtb";
    };
    sbc.board.xunlong.opi5.ubootPackage = lib.mkIf (cfg.hardwareVariant == "b") sbcPkgs.ubootOrangePi5b;

    # GPU requres firmware
    hardware.enableRedistributableFirmware = true;

    sbc.board = {
      vendor = "xunlong";
      model = "OrangePi5${variantText}";
      dtRoot = "xunlong,orangepi-5";

      # i2c0: CPU power management, no user function
      i2c.devices.i2c1 = {
        # Note: M2/M4 are mutually exclusive, it changes what pins i2c1 is on.
        status = "disabled";
        enableMethod.dtOverlay = {
          enable = true;
          pinctrl-names = "default";
          # Pins 16, 18
          pinctrl-0 = lib.mkDefault ["i2c1m4_xfer"];
          # FIXME: Could there be a more user-friendly method of selecting the pins
          # for the interface than making the user know they need to set pinctrl-0 to
          # i2c1m2_xfer to get i2c1 onto pins 12, 15?
        };
      };
      # i2c2: NPU power management, no user function
      i2c.devices.i2c3 = {
        status = "disabled";
        enableMethod.dtOverlay = {
          enable = true;
          pinctrl-names = "default";
          # Pins 19, 21
          pinctrl-0 = lib.mkDefault ["i2c3m0_xfer"];
        };
      };
      i2c.devices.i2c5 = {
        status = "disabled";
        enableMethod.dtOverlay = {
          enable = true;
          pinctrl-names = "default";
          # Pins 3, 5
          pinctrl-0 = lib.mkDefault ["i2c5m3_xfer"];
        };
      };
      # i2c6: HYM8563 RTC, no user function

      uart.devices.uart0 = {
        # Pins 8/10
        status = "disabled";
        deviceName = "ttyS0";
        console = false;
        enableMethod.dtOverlay = {
          enable = true;
          # Pins 8, 10
          pinctrl-0 = lib.mkDefault ["uart0m2_xfer"];
        };
      };
      uart.devices.uart1 = {
        status = "disabled";
        deviceName = "ttyS1";
        console = false;
        enableMethod.dtOverlay = {
          enable = true;
          # Pins 3, 5
          pinctrl-0 = lib.mkDefault ["uart1m1_xfer"];
        };
      };
      uart.devices.uart2 = {
        status = "okay";
        baud = 1500000;
        deviceName = "ttyS2";
        console = true;
        disableMethod.dtOverlay.enable = true;
      };
      uart.devices.uart3 = {
        status = "disabled";
        deviceName = "ttyS3";
        console = false;
        enableMethod.dtOverlay = {
          enable = true;
          # Pins 19, 21
          pinctrl-0 = lib.mkDefault ["uart3m0_xfer"];
        };
      };
      uart.devices.uart4 = {
        status = "disabled";
        deviceName = "ttyS4";
        console = false;
        enableMethod.dtOverlay = {
          enable = true;
          # Pins 16, 18
          pinctrl-0 = lib.mkDefault ["uart4m0_xfer"];
        };
      };
      # UART 9 is BT on 5b

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
