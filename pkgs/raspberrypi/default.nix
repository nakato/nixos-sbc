{
  buildSBCUBoot,
  stdenvNoCC,
  mtools,
  dosfstools,
  raspberrypi-armstubs,
  raspberrypifw,
  writeText,
  lib,
  ...
}: let
  ubootRaspberryPi4 = buildSBCUBoot {
    filesToInstall = ["u-boot.bin" "arch/arm/dts/bcm2711-rpi-4-b.dtb"];
    defconfig = "rpi_4_defconfig";
    extraMeta.platforms = ["aarch64-linux"];

    # Recreate the RPi patch in the new text env.
    # But don't use a patch, because it breaks needlessly between versions.
    postPatch = ''
      sed -i \
        -e 's|scriptaddr=0x02400000|scriptaddr=0x04500000|' \
        -e 's|pxefile_addr_r=0x02500000|pxefile_addr_r=0x04600000|' \
        -e 's|fdt_addr_r=0x02600000|fdt_addr_r=0x04700000|' \
        -e 's|ramdisk_addr_r=0x02700000|ramdisk_addr_r=0x04800000|' \
        board/raspberrypi/rpi/rpi.env

      cp ${./mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
    '';
  };

  rpiFirmwareConfigTxt = writeText "config.txt" ''
    [pi4]
    kernel=u-boot-pi4.bin
    enable_gic=1
    armstub=armstub8-gic.bin

    [all]
    arm_64bit=1
    enable_uart=1
    avoid_warnings=1
  '';
in {
  inherit ubootRaspberryPi4;

  # Treat the entire RPi firmware partition as though it's an immutable blob
  # similar to how firmware on most (all?) other SBCs.
  # Without treating it this way it becomes a source of in-determinism in producing
  # reproducable OS images.
  raspberryPiFirmware = stdenvNoCC.mkDerivation {
    name = "raspberryPiFirmware.img";

    nativeBuildInputs = [dosfstools mtools];
    dontFixup = true;

    buildPhase = ''
      size=$((32 * 1024 * 1024))

      truncate -s $size firmware.img
      mkfs.vfat --invariant -i 0x2178694e -n firmware firmware.img


      mkdir firmwareFiles
      # Generic
      cp ${raspberrypifw}/share/raspberrypi/boot/{bootcode.bin,fixup*.dat,start*.elf} firmwareFiles/
      cp ${rpiFirmwareConfigTxt} firmwareFiles/config.txt

      # Pi4
      cp ${ubootRaspberryPi4}/u-boot.bin firmwareFiles/u-boot-pi4.bin
      cp ${ubootRaspberryPi4}/bcm2711-rpi-4-b.dtb firmwareFiles/
      cp ${raspberrypi-armstubs}/armstub8-gic.bin firmwareFiles/

      find firmwareFiles -exec touch --date=1970-01-01 {} +
      for f in $(find firmwareFiles -type f | sort); do
        mcopy -pvm -i firmware.img "$f" "::/$(basename $f)"
      done

      fsck.vfat -vn firmware.img
    '';

    dontUnpack = true;
    installPhase = ''
      cp firmware.img $out
    '';
    meta = {
      license = lib.licenses.unfreeRedistributableFirmware;
    };
  };
}
