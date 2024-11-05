{
  armTrustedFirmwareTools,
  buildArmTrustedFirmware,
  buildSBCUBoot,
  dtc,
  fetchFromGitHub,
  ncurses,
  pkg-config,
  ubootTools,
  linuxKernel,
  linux_6_11,
  lib,
  ...
}: rec {
  ubootBananaPiR4 =
    buildSBCUBoot {
      defconfig = "mt7988_sd_rfb_defconfig";
      extraMeta.platforms = ["aarch64-linux"];
      extraNativeBuildInputs = [pkg-config ncurses armTrustedFirmwareTools];
      extraPatches = [
        ./mt7988-persistent-mac-from-cpu-uid.patch
      ];
      postPatch = ''
        cp ${./mt7988-nixos.env} board/mediatek/mt7988/mt7988-nixos.env
        # Should include via CONFIG_DEVICE_TREE_INCLUDES, but regression in
        # makefile is causing issues.
        # Regression caused by a958988b62eb9ad33c0f41b4482cfbba4aa71564.
        #
        # For now, work around issue by copying dtsi into tree and referencing
        # it in extraConfig using the relative path.
        cp ${./mt7988-mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
      '';
      extraConfig = ''
        CONFIG_ENV_SOURCE_FILE="mt7988-nixos"
        # Unessessary as it's not actually used anywhere, value copied verbatum into env
        CONFIG_DEFAULT_FDT_FILE="mediatek/mt7988a-bananapi-bpi-r4.dtb"
        # Big kernels
        CONFIG_SYS_BOOTM_LEN=0x6000000
        # The following are used in the tooling to fixup MAC addresses
        CONFIG_BOARD_LATE_INIT=y
        CONFIG_SHA1=y
      '';
      postBuild = ''
        fiptool create --soc-fw ${armTrustedFirmwareMT7988}/bl31.bin --nt-fw u-boot.bin fip.bin
        cp ${armTrustedFirmwareMT7988}/bl2.img bl2.img
      '';
      # FIXME: Should bl2 bundle here?
      filesToInstall = ["bl2.img" "fip.bin"];
    };

  armTrustedFirmwareMT7988 =
    (buildArmTrustedFirmware rec {
      extraMakeFlags = ["USE_MKIMAGE=1" "DRAM_USE_COMB=1" "BOOT_DEVICE=sdmmc" "bl2" "bl31"];
      platform = "mt7988";
      extraMeta.platforms = ["aarch64-linux"];
      filesToInstall = ["build/${platform}/release/bl2.img" "build/${platform}/release/bl31.bin"];
    })
    .overrideAttrs (oldAttrs: {
      src = fetchFromGitHub {
        owner = "mtk-openwrt";
        repo = "arm-trusted-firmware";
        # mtksoc HEAD 2024-08-02
        rev = "bacca82a8cac369470df052a9d801a0ceb9b74ca";
        hash = "sha256-n5D3styntdoKpVH+vpAfDkCciRJjCZf9ivrI9eEdyqw=";
      };
      version = "2.10.0-mtk";
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [dtc ubootTools];
    });


  linuxPackages_frankw_6_11_bananaPiR4 = linuxKernel.packagesFor (linux_6_11.override {
    autoModules = false;

    structuredExtraConfig = with lib.kernel; {
      BTRFS_FS = module;
      BTRFS_FS_POSIX_ACL = yes;

      AUTOFS_FS = module;

      # Used by system.etc.overlay.enable as part of a perl-less build.
      EROFS_FS = module;
      EROFS_FS_ZIP_LZMA = yes;
      EROFS_FS_ZIP_DEFLATE = yes;
      EROFS_FS_ZIP_ZSTD = yes;
      EROFS_FS_PCPU_KTHREAD = yes;

      # Disable extremely unlikely features to reduce build storage requirements and time.
      FB = lib.mkForce no;
      DRM = lib.mkForce no;
      SOUND = no;
      INFINIBAND = lib.mkForce no;
    };

    argsOverride = {
      src = fetchFromGitHub {
        owner = "frank-w";
        repo = "BPI-Router-Linux";
        # 6.11-main HEAD 2024-10-07
        rev = "7a99830e634e841ea97796c35bbe0cf8e038ad9f";
        hash = "sha256-6ng5eY8yM01asQjyF6IE1UGuZ6KeEsH2bwkVKwgx1xg=";
      };
      version = "6.11.0-bpi-r4";
      modDirVersion = "6.11.0-bpi-r4";
    };

    defconfig = "mt7988a_bpi-r4_defconfig";

    extraMeta.vendorKernel = true;
  });

  linuxPackages_frankw_latest_bananaPiR4 = linuxPackages_frankw_6_11_bananaPiR4;
}
