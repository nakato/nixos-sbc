{
  patchSBCUBoot,
  lib,
  armTrustedFirmwareRK3588,
  buildUBoot,
  linuxPackages_6_10,
  rkbin,
  ...
}: let
  ubootOrangePi5 = buildUBoot rec {
    defconfig = "orangepi-5-rk3588s_defconfig";
    extraMeta = {
      platforms = ["aarch64-linux"];
    };
    buildInputs = [armTrustedFirmwareRK3588 rkbin];
    BL31 = "${armTrustedFirmwareRK3588}/bl31.elf";
    ROCKCHIP_TPL = rkbin.TPL_RK3588;
    filesToInstall = ["u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" "u-boot-rockchip-spi.bin"];
  };
  overrideUbootAttrs = bVariant: oldAttrs: {
    # 2024.07 DTS can be switched to upstream after 2024.10 release.
    # as it has been synced with upstream.
    postPatch =
      oldAttrs.postPatch
      + ''
        cp ${./mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
        cp ${./rk3588s-orangepi-5b.2024-07.dts} dts/upstream/src/arm64/rockchip/rk3588s-orangepi-5b.dts
        cp ${./rk3588s-orangepi-5b-u-boot.dtsi} arch/arm/dts/rk3588s-orangepi-5b-u-boot.dtsi
      '';
    postConfigure = lib.optionalString bVariant ''
      sed -i 's/rk3588s-orangepi-5/rk3588s-orangepi-5b/' .config
    '';
    extraConfig =
      oldAttrs.extraConfig
      + ''
        CONFIG_DEVICE_TREE_INCLUDES="nixos-mmcboot.dtsi"
      ''
      + lib.optionalString bVariant ''
        CONFIG_MMC_SDHCI=y
        CONFIG_MMC_SDHCI_SDMA=y
        CONFIG_MMC_SDHCI_ROCKCHIP=y
      '';
  };
in {
  ubootOrangePi5 = (patchSBCUBoot ubootOrangePi5).overrideAttrs (overrideUbootAttrs false);
  ubootOrangePi5b = (patchSBCUBoot ubootOrangePi5).overrideAttrs (overrideUbootAttrs true);
  orangePi5bDTBs = linuxPackages_6_10.kernel.overrideAttrs (oldAttrs: {
    pname = "linux-opi5b-dtbs";
    buildFlags = ["dtbs"];
    installTargets = ["dtbs_install"];
    installFlags = ["INSTALL_DTBS_PATH=$(out)/dtbs"];
    postInstall = null;
    postPatch =
      oldAttrs.postPatch
      + ''
        cp ${./rk3588s-orangepi-5b.dts} arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5b.dts
        echo 'dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-orangepi-5b.dtb' >> arch/arm64/boot/dts/rockchip/Makefile
      '';
  });
}
