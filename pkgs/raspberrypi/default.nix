{ buildUBoot
, dtc
, fetchurl
, fetchpatch
, stdenvNoCC
, mtools
, dosfstools
, raspberrypi-armstubs
, raspberrypifw
, runCommand
, ubootRaspberryPi4_64bit
, writeText
, ...}:
let
  uBootArgs = {
    version = "2024.01";
    src = fetchurl {
      url = "ftp://ftp.denx.de/pub/u-boot/u-boot-2024.01.tar.bz2";
      hash = "sha256-uZYR8e0je/NUG9yENLaMlqbgWWcGH5kkQ8swqr6+9bM=";
    };
    filesToInstall = [ "u-boot.bin" "arch/arm/dts/bcm2711-rpi-4-b.dtb" ];
    defconfig = "rpi_4_defconfig";
    extraConfig = ''
      CONFIG_AUTOBOOT=y
      CONFIG_BOOTDELAY=1
      CONFIG_USE_BOOTCOMMAND=y
      # Use bootstd and bootflow over distroboot for extlinux support
      CONFIG_BOOTSTD_DEFAULTS=y
      CONFIG_BOOTSTD_FULL=y
      CONFIG_CMD_BOOTFLOW_FULL=y
      CONFIG_BOOTCOMMAND="bootflow scan -lb"
      CONFIG_DEVICE_TREE_INCLUDES="nixos-mmcboot.dtsi"
      # Disable saving env, it isn't tested and probably doesn't work.
      CONFIG_ENV_IS_NOWHERE=y
      CONFIG_LZ4=y
      CONFIG_BZIP2=y
      CONFIG_ZSTD=y
      # Boot on root ext4 support
      CONFIG_CMD_EXT4=y
      # Boot on root btrfs support
      CONFIG_FS_BTRFS=y
      CONFIG_CMD_BTRFS=y
    '';
    extraMeta.platforms = ["aarch64-linux"];
  };

  patchUBootDerivation = pkg: (pkg.overrideAttrs (oldAttrs: {
    # No RPi patches
    patches = [
      (fetchpatch {
        name = "u-boot-fs-btrfs-fix-reading-when-length-specified.patch";
        url = "https://patchwork.ozlabs.org/project/uboot/patch/20231111151904.149009-1-CFSworks@gmail.com/raw/";
        hash = "sha256-nn7hPvjxNUji9nCAJNGLV4bvL5j0LrkL8FiyYM6lFsA=";
      })
    ];

    # Recreate the RPi patch in the new text env.
    # But don't use a patch, because it breaks needlessly between versions.
    postPatch = oldAttrs.postPatch + ''
      sed -i \
        -e 's|scriptaddr=0x02400000|scriptaddr=0x04500000|' \
        -e 's|pxefile_addr_r=0x02500000|pxefile_addr_r=0x04600000|' \
        -e 's|fdt_addr_r=0x02600000|fdt_addr_r=0x04700000|' \
        -e 's|ramdisk_addr_r=0x02700000|ramdisk_addr_r=0x04800000|' \
        board/raspberrypi/rpi/rpi.env

      cp ${./mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
    '';

    makeFlags = [ "DTC=${dtc}/bin/dtc" ];
  }));

  ubootRaspberryPi4 = patchUBootDerivation (buildUBoot uBootArgs);

  rpiFirmwareConfigTxt = writeText "config.txt" ''
    [pi4]¬
    kernel=u-boot-pi4.bin
    enable_gic=1
    armstub=armstub8-gic.bin

    [all]
    arm_64bit=1
    enable_uart=1
    avoid_warnings=1
  '';
in
{
  inherit ubootRaspberryPi4;

  # Treat the entire RPi firmware partition as though it's an immutable blob
  # similar to how firmware on most (all?) other SBCs.
  # Without treating it this way it becomes a source of in-determinism in producing
  # reproducable OS images.
  raspberryPiFirmware = stdenvNoCC.mkDerivation {
    name = "raspberryPiFirmware.img";

    nativeBuildInputs = [ dosfstools mtools ];

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
  };
}
