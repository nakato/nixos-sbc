{
  buildArmTrustedFirmware,
  buildLinux,
  buildUBoot,
  dtc,
  fetchpatch,
  fetchurl,
  fetchFromGitHub,
  lib,
  linuxKernel,
  linux_6_9,
  ncurses,
  pkg-config,
  ubootTools,
  ...
}: rec {
  ubootBananaPiR3 = let
    extraPatches = [
      ./mt7986-persistent-mac-from-cpu-uid.patch
      ./mt7986-persistent-wlan-mac-from-cpu-uid.patch
      (fetchpatch {
        name = "u-boot-fs-btrfs-fix-reading-when-length-specified.patch";
        url = "https://patchwork.ozlabs.org/project/uboot/patch/20231111151904.149009-1-CFSworks@gmail.com/raw/";
        hash = "sha256-nn7hPvjxNUji9nCAJNGLV4bvL5j0LrkL8FiyYM6lFsA=";
      })
    ];
  in
    (buildUBoot {
      defconfig = "mt7986a_bpir3_sd_defconfig";
      extraMeta.platforms = ["aarch64-linux"];
      extraPatches = extraPatches;
      postPatch = ''
        patchShebangs tools
        patchShebangs scripts

        cp ${./mt7986-nixos.env} board/mediatek/mt7986/mt7986-nixos.env
        # Should include via CONFIG_DEVICE_TREE_INCLUDES, but regression in
        # makefile is causing issues.
        # Regression caused by a958988b62eb9ad33c0f41b4482cfbba4aa71564.
        #
        # For now, work around issue by copying dtsi into tree and referencing¬
        # it in extraConfig using the relative path.¬
        cp ${./mt7986-mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
      '';
      extraConfig = ''
        CONFIG_AUTOBOOT=y
        CONFIG_BOOTDELAY=1
        CONFIG_USE_BOOTCOMMAND=y
        # Use bootstd and bootflow over distroboot for extlinux support
        CONFIG_BOOTSTD_DEFAULTS=y
        CONFIG_BOOTSTD_FULL=y
        CONFIG_CMD_BOOTFLOW_FULL=y
        CONFIG_ENV_SOURCE_FILE="mt7986-nixos"
        CONFIG_DEVICE_TREE_INCLUDES="nixos-mmcboot.dtsi"
        # Unessessary as it's not actually used anywhere, value copied verbatum into env
        CONFIG_DEFAULT_FDT_FILE="mediatek/mt7986a-bananapi-bpi-r3.dtb"
        # Big kernels
        CONFIG_SYS_BOOTM_LEN=0x6000000
        # Disable saving env, it isn't tested and probably doesn't work.
        CONFIG_ENV_IS_NOWHERE=y
        CONFIG_LZ4=y
        CONFIG_BZIP2=y
        CONFIG_ZSTD=y
        # The following are used in the tooling to fixup MAC addresses
        CONFIG_BOARD_LATE_INIT=y
        CONFIG_SHA1=y
        CONFIG_OF_BOARD_SETUP=y
        # Boot on root ext4 support
        CONFIG_CMD_EXT4=y
        # Boot on root btrfs support
        CONFIG_FS_BTRFS=y
        CONFIG_CMD_BTRFS=y
      '';
      filesToInstall = ["u-boot.bin"];
      src = fetchurl {
        url = "ftp://ftp.denx.de/pub/u-boot/u-boot-2024.01.tar.bz2";
        hash = "sha256-uZYR8e0je/NUG9yENLaMlqbgWWcGH5kkQ8swqr6+9bM=";
      };
      version = "2024.01";
    })
    .overrideAttrs (oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkg-config ncurses];
      patches = extraPatches;
      makeFlags = ["DTC=${dtc}/bin/dtc"];
    });

  # TODO: Remove fip from extraMakeFlags, and do not pass uboot into this build.
  # Build and package ./tools/fiptool/fiptool or work out how to use the fiptool.py in uboot binman.
  # Build uboot, build this, commbine the two with fiptool create --soc-fw bl32.bin --nt-fw u-boot.bin u-boot.fip
  armTrustedFirmwareMT7986 =
    (buildArmTrustedFirmware rec {
      extraMakeFlags = ["USE_MKIMAGE=1" "DRAM_USE_DDR4=1" "BOOT_DEVICE=sdmmc" "BL33=${ubootBananaPiR3}/u-boot.bin" "all" "fip"];
      platform = "mt7986";
      extraMeta.platforms = ["aarch64-linux"];
      filesToInstall = ["build/${platform}/release/bl2.img" "build/${platform}/release/fip.bin"];
    })
    .overrideAttrs (oldAttrs: {
      src = fetchFromGitHub {
        owner = "mtk-openwrt";
        repo = "arm-trusted-firmware";
        # mtksoc HEAD 2023-03-10
        rev = "7539348480af57c6d0db95aba6381f3ee7483779";
        hash = "sha256-OjM+metlaEzV7mXA8QHYEQd94p8zK34dLTqbyWQh1bQ=";
      };
      version = "2.7.0-mtk";
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [dtc ubootTools];
    });

  linuxPackages_6_9_bananaPiR3 = linuxKernel.packagesFor (linux_6_9.override {
    kernelPatches = [
      {
        # Cold boot PCIe/NVMe have stability issues.
        # See: https://forum.banana-pi.org/t/bpi-r3-problem-with-pcie/15152
        #
        # FrankW's first patch added a 100ms sleep, this was rejected upstream.
        # Jianjun posted a patch to the forum for testing, and it appears to me
        # to have accidentally missed a write to the registers between the two
        # sleeps.  This version is modified to include the write, and results
        # in the PCI bridge appearing reliably, but not the NVMe device.
        #
        # Without this patch, the PCI bridge is not present, and rescan does
        # not discover it.  Removing the bridge and then rescanning repeatably
        # gets the NVMe working on cold-boot.
        name = "PCI: mediatek-gen3: handle PERST after reset";
        patch = ./linux-mtk-pcie.patch;
      }
    ];

    structuredExtraConfig = with lib.kernel; {
      # Disable extremely unlikely features to reduce build storage requirements and time.
      FB = lib.mkForce no;
      DRM = lib.mkForce no;
      SOUND = no;
      INFINIBAND = lib.mkForce no;

      # PCIe
      PCIE_MEDIATEK = yes;
      PCIE_MEDIATEK_GEN3 = yes;
      # SD/eMMC
      MTD_NAND_ECC_MEDIATEK = yes;
      # Net
      BRIDGE = yes;
      HSR = yes;
      NET_DSA = yes;
      NET_DSA_TAG_MTK = yes;
      NET_DSA_MT7530 = yes;
      NET_VENDOR_MEDIATEK = yes;
      PCS_MTK_LYNXI = yes;
      NET_MEDIATEK_SOC_WED = yes;
      NET_MEDIATEK_SOC = yes;
      NET_MEDIATEK_STAR_EMAC = yes;
      MEDIATEK_GE_PHY = yes;
      # WLAN
      WLAN = yes;
      WLAN_VENDOR_MEDIATEK = yes;
      MT76_CORE = module;
      MT76_LEDS = yes;
      MT76_CONNAC_LIB = module;
      MT7915E = module;
      MT798X_WMAC = yes;
      # Pinctrl
      EINT_MTK = yes;
      PINCTRL_MTK = yes;
      PINCTRL_MT7986 = yes;
      # Thermal
      MTK_THERMAL = yes;
      MTK_SOC_THERMAL = yes;
      MTK_LVTS_THERMAL = yes;
      # Clk
      COMMON_CLK_MEDIATEK = yes;
      COMMON_CLK_MEDIATEK_FHCTL = yes;
      COMMON_CLK_MT7986 = yes;
      COMMON_CLK_MT7986_ETHSYS = yes;
      # other
      MEDIATEK_WATCHDOG = yes;
      REGULATOR_MT6380 = yes;
    };
  });
  linuxPackages_latest_bananaPiR3 = linuxPackages_6_9_bananaPiR3;
}
