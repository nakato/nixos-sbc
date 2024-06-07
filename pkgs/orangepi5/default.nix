{
  lib,
  dtc,
  fetchurl,
  fetchpatch,
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
      ''
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
      ''
      + lib.optionalString bVariant ''
        CONFIG_MMC_SDHCI=y
        CONFIG_MMC_SDHCI_SDMA=y
        CONFIG_MMC_SDHCI_ROCKCHIP=y
      '';
  };
in {
  ubootOrangePi5 = ubootOrangePi5.overrideAttrs (overrideUbootAttrs false);
  ubootOrangePi5b = (ubootOrangePi5.overrideAttrs (overrideUbootAttrs true)).override {defconfig = "orangepi-5b-rk3588s_defconfig";};
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
