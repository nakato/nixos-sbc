{
  patchSBCUBoot,
  lib,
  armTrustedFirmwareRK3588,
  buildUBoot,
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
    postPatch =
      oldAttrs.postPatch
      + ''
        cp ${./mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
        cp ${./rk3588s-orangepi-5b.dts} dts/upstream/src/arm64/rockchip/rk3588s-orangepi-5b.dts
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
}
