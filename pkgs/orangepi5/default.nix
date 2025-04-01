{
  patchSBCUBoot,
  lib,
  armTrustedFirmwareRK3588,
  buildUBoot,
  linuxPackages_6_14,
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
  ubootOrangePi5Max = buildUBoot rec {
    defconfig = "orangepi-5-plus-rk3588_defconfig";
    extraMeta = {
      platforms = ["aarch64-linux"];
    };
    buildInputs = [armTrustedFirmwareRK3588 rkbin];
    BL31 = "${armTrustedFirmwareRK3588}/bl31.elf";
    ROCKCHIP_TPL = rkbin.TPL_RK3588;
    filesToInstall = ["u-boot.itb" "idbloader.img" "u-boot-rockchip.bin" "u-boot-rockchip-spi.bin"];
  };
  ubootOrangePi5MaxOverrides = oldAttrs: {
    # rk3588s-orangepi-5b-u-boot.dtsi should be fine, just re-use it.
    postPatch = let
      kernTar = linuxPackages_6_14.kernel.src;
      kernTarVersion = if linuxPackages_6_14.kernel.modDirVersion == "${linuxPackages_6_14.kernel.version}.0" then linuxPackages_6_14.kernel.version else linuxPackages_6_14.kernel.modDirVersion;
      dtsPath = "linux-${kernTarVersion}/arch/arm64/boot/dts/rockchip/";
    in
      oldAttrs.postPatch
      + ''
        mkdir tmpdtbs
        tar -C tmpdtbs -xf ${kernTar} ${dtsPath}
        cp ${./mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
        cp tmpdtbs/${dtsPath}/{rk3588-orangepi-5-max.dts,rk3588-orangepi-5-compact.dtsi,rk3588-orangepi-5.dtsi,rk3588.dtsi,rk3588-opp.dtsi,rk3588-extra.dtsi,rk3588-base.dtsi,rk3588-extra-pinctrl.dtsi} dts/upstream/src/arm64/rockchip/
        rm -rf tmpdtbs
        cp ${./rk3588s-orangepi-5b-u-boot.dtsi} arch/arm/dts/rk3588-orangepi-5-max-u-boot.dtsi
      '';
    postConfigure = ''
      sed -i 's/rk3588-orangepi-5-plus/rk3588-orangepi-5-max/' .config
    '';
    extraConfig =
      oldAttrs.extraConfig
      + ''
        CONFIG_DEVICE_TREE_INCLUDES="nixos-mmcboot.dtsi"
      '';
  };
in {
  ubootOrangePi5 = (patchSBCUBoot ubootOrangePi5).overrideAttrs (overrideUbootAttrs false);
  ubootOrangePi5b = (patchSBCUBoot ubootOrangePi5).overrideAttrs (overrideUbootAttrs true);
  ubootOrangePi5Max = (patchSBCUBoot ubootOrangePi5Max).overrideAttrs ubootOrangePi5MaxOverrides;
}
