{
  patchSBCUBoot,
  lib,
  ubootOrangePi5,
  linuxPackages_6_9,
  ...
}: let
  overrideUbootAttrs = bVariant: oldAttrs: {
    defconfig =
      if bVariant
      then "orangepi-5b-rk3588s_defconfig"
      else "orangepi-5-rk3588s_defconfig";
    postPatch =
      oldAttrs.postPatch
      + ''
        cp ${./mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
        cp ${./rk3588s-orangepi-5b.dts} arch/arm/dts/rk3588s-orangepi-5b.dts
        cp ${./rk3588s-orangepi-5b-u-boot.dtsi} arch/arm/dts/rk3588s-orangepi-5b-u-boot.dtsi
        sed -i 's/rk3588s-orangepi-5.dtb/rk3588s-orangepi-5.dtb rk3588s-orangepi-5b.dtb/' arch/arm/dts/Makefile
        cp configs/orangepi-5-rk3588s_defconfig configs/orangepi-5b-rk3588s_defconfig
        sed -i 's/rk3588s-orangepi-5/rk3588s-orangepi-5b/' configs/orangepi-5b-rk3588s_defconfig
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
    meta = oldAttrs.meta // {skipBuildCache = true;};
  };
in {
  ubootOrangePi5 = (patchSBCUBoot ubootOrangePi5).overrideAttrs (overrideUbootAttrs false);
  ubootOrangePi5b = (patchSBCUBoot ubootOrangePi5).overrideAttrs (overrideUbootAttrs true);
  orangePi5bDTBs = linuxPackages_6_9.kernel.overrideAttrs (oldAttrs: {
    pname = "linux-opi5b-dtbs";
    buildFlags = ["dtbs"];
    installTargets = ["dtbs_install"];
    installFlags = ["INSTALL_DTBS_PATH=$(out)/dtbs"];
    postInstall = null;
    postPatch =
      oldAttrs.postPatch
      + ''
        cp ${./rk3588s-orangepi-5b.dts} arch/arm64/boot/dts/rockchip/
        echo "dtb-$(CONFIG_ARCH_ROCKCHIP) += rk3588s-orangepi-5b.dtb" >> arch/arm64/boot/dts/rockchip/Makefile
      '';
  });
}
