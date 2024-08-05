{
  lib,
  sbcPkgs,
  ...
}: {
  imports = [
    ./sd-image-mt7988.nix
  ];

  options.sbc.board.bananapi.bpir4 = {};

  config = {
    sbc.enable = true;

    sbc.board = {
      vendor = "BananaPi";
      model = "BPiR4";
      dtRoot = "mediatek,mt7988a";

      i2c.devices.i2c0 = {
        status = "okay";
      };

      i2c.devices.i2c1 = {
        status = "disabled";
        enableMethod.dtOverlay = {
          enable = true;
          pinctrl-names = "default";
          # Pins 3, 5
          pinctrl-0 = lib.mkDefault ["i2c1_pins"];
        };
      };

      i2c.devices.i2c2 = {
        status = "okay";
      };

      uart.devices.uart0 = {
        status = "okay";
        baud = 115200;
        deviceName = "ttyS0";
        console = true;
      };

      # uart.devices.uart1 not currently in DT.  GPIO header pins 11, 13.
    };

    # Custom kernel is required as bpi-r4 does not have enough upstream support.
    boot.kernelPackages = sbcPkgs.linuxPackages_frankw_latest_bananaPiR4;

    boot.kernelParams = [
      # keep boot clocks on
      # currently required for boot
      # long-term this should not be needed as the drivers and device tree mature
      "clk_ignore_unused=1"
    ];

    # We exclude a number of modules included in the default list. A non-insignificant amount do
    # not apply to embedded hardware like this, so simply skip the defaults.
    boot.initrd.includeDefaultModules = false;
    boot.initrd.kernelModules = ["mii"];
    boot.initrd.availableKernelModules = ["nvme"];

    hardware.deviceTree.filter = "mt7988a-bananapi-bpi-r4.dtb";
    hardware.deviceTree.overlays = [
      {
        name = "BananaPi bpir4 Enable SD card interface";
        dtsFile = ./mt7988a-bananapi-bpi-r4-sd.dts;
      }
    ];
  };
}
