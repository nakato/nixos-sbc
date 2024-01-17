{ config
, lib
, sbcPkgs
, ...}:
let
  cfg = config.sbc.board.bananapi.bpir3;
in
{
  imports = [
    ./wifi.nix
  ];

  options.sbc.board.bananapi.bpir3 = with lib; {
    pcieFixup = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        If enabled, during initrd stage1, if no PCIe device is detected a PCIe
        bus rescan will be attempted to give the system an attempt to find the
        device.

        This is only required for some PCIe devices to detect during cold boot.
        If you don't have a device, it won't do anything, if a PCIe device is
        found, it skips the re-scan.
      '';
    };
  };

  config = {
    sbc.enable = true;

    sbc.board.spec = {
      name = "BananaPi BPi R3";
      dtRoot = "mediatek,mt7986a";
      wifi.wifi.status = "okay";
      i2c.i2c0 = {
        status = "okay";
      };
      uart.uart0 = {
        status = "okay";
        baud = 115200;
        deviceName = "ttyS0";
      };
    };

    # Custom kernel is required as a lot of MTK components misbehave when built as modules.
    # They fail to load properly, leaving the system without working ethernet, they'll oops on
    # remove. MTK-DSA parts and PCIe were observed to do this.
    boot.kernelPackages = sbcPkgs.linuxPacakges_latest_bananaPiR3;

    # We exclude a number of modules included in the default list. A non-insignificant amount do
    # not apply to embedded hardware like this, so simply skip the defaults.
    boot.initrd.includeDefaultModules = false;
    boot.initrd.kernelModules = [ "mii" ];

    hardware.deviceTree.filter = "mt7986a-bananapi-bpi-r3.dtb";
    hardware.deviceTree.overlays = [
      {
        # FIXME: Apply the precompiled dtbo file provided by the kernel instead of this copy of it.
        name = "BananaPi BPiR3 Enable SD card interface";
        dtsFile = ./mt7986a-bananapi-bpi-r3-sd.dts;
      }
      {
        name = "BananaPi BPiR3 Disable RST and swap WPS button to be RESET_KEY";
        dtsFile = ./mt7986a-bananapi-bpi-r3-pcie-button.dts;
      }
    ];

    boot.initrd.preDeviceCommands = lib.mkIf cfg.pcieFixup ''
      if [ ! -d /sys/bus/pci/devices/0000:01:00.0 ]; then
        if [ -d /sys/bus/pci/devices/0000:00:00.0 ]; then
          # Remove PCI bridge, then rescan.  NVMe init crashes if PCI bridge not removed first
          echo 1 > /sys/bus/pci/devices/0000:00:00.0/remove
          # Rescan brings PCI root back and brings the NVMe device in.
          echo 1 > /sys/bus/pci/rescan
        else
          info "PCIe bridge missing"
        fi
      fi
    '';
  };
}
