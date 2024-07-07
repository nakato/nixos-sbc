{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../sd-image-rpi.nix
  ];

  options.sbc.board.raspberrypi.rpi4 = {};

  config = {
    sbc.enable = true;

    sbc.board = {
      vendor = "RaspberryPi";
      model = "rpi4";
      dtRoot = "brcm,bcm2711";

      i2c.devices.i2c1 = {
        status = "disabled";
      };

      # uart0 is hardware uart, is enabled, but consumed by bluetooth
      # uart1 is software uart, this disable some power optimisations.
      # uart2-5 are hardware PL011 devices
      # 2: GPIO 0, 1   - PINS: 27, 28
      # 3: GPIO 4, 5   - PINS:  7, 29
      # 4: GPIO 8, 9   - PINS: 24, 21
      # 5: GPIO 12, 13 - PINS: 32, 33
      uart.devices.uart0 = {
        status = "okay";
        baud = 115200;
        deviceName = "ttyAMA0";
        console = false;
      };

      uart.devices.uart1 = {
        status = "okay";
        baud = 115200;
        deviceName = "ttyS1";
        console = true;
      };

      # Will these device names be accurate if 3 is enabled and 2 is not?
      uart.devices.uart2 = {
        status = "disabled";
        baud = 115200;
        deviceName = "ttyAMA1";
        console = false;
      };

      uart.devices.uart3 = {
        status = "disabled";
        baud = 115200;
        deviceName = "ttyAMA2";
        console = false;
      };

      uart.devices.uart4 = {
        status = "disabled";
        baud = 115200;
        deviceName = "ttyAMA3";
        console = false;
      };

      uart.devices.uart5 = {
        status = "disabled";
        baud = 115200;
        deviceName = "ttyAMA4";
        console = false;
      };
    };

    boot = {
      initrd = {
        availableKernelModules = [
          "pcie_brcmstb"
          "reset-raspberrypi"
          "usbhid"
          "usb_storage"
        ];
        kernelModules = ["vc4"];
      };
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
    };

    hardware.enableRedistributableFirmware = true;
    environment.systemPackages = [pkgs.libraspberrypi];

    hardware.deviceTree.filter = "bcm2711-rpi-*.dtb";

    # TODO: CPU Revision overlay, which would normally come from firmware
    # See list https://elinux.org/RPi_HardwareHistory
    hardware.deviceTree.overlays = [];
  };
}
