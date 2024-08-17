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
  linux_6_10,
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


  linuxPackages_frankw_6_10_bananaPiR4 = linuxKernel.packagesFor (linux_6_10.override {
    argsOverride = {
      src = fetchFromGitHub {
        owner = "frank-w";
        repo = "BPI-Router-Linux";
        # 6.10-main HEAD 2024-08-06
        rev = "7f8ea2c961d9b931b185d9fa440d904f66d9a786";
        hash = "sha256-k4ou1blQxtE2KxuM4366ShbH0y4UZ8JqpDcZD9B5JoI=";
      };
      version = "6.10.0-bpi-r4";
      modDirVersion = "6.10.0-bpi-r4";
    };

    defconfig = "mt7988a_bpi-r4_defconfig";

    extraMeta.vendorKernel = true;
  });

  linuxPackages_frankw_latest_bananaPiR4 = linuxPackages_frankw_6_10_bananaPiR4;
}
