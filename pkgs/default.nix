{pkgs}: let
  u-boot = pkgs.callPackage ./u-boot {};
  pkgsArgs = {inherit (u-boot) buildSBCUBoot patchSBCUBoot;};

  bananaPiR3 = pkgs.callPackage ./bananaPiR3 pkgsArgs;
  bananaPiR4 = pkgs.callPackage ./bananaPiR4 pkgsArgs;
  pine64rock64 = pkgs.callPackage ./pine64rock64 pkgsArgs;
  raspberrypi = pkgs.callPackage ./raspberrypi pkgsArgs;
  orangepi5 = pkgs.callPackage ./orangepi5 pkgsArgs;
in {
  inherit (bananaPiR3) armTrustedFirmwareMT7986 linuxPackages_latest_bananaPiR3 linuxPackages_6_14_bananaPiR3 ubootBananaPiR3 linuxPackages_6_14_bananaPiR3_minimal;
  inherit (bananaPiR4) armTrustedFirmwareMT7988 linuxPackages_frankw_latest_bananaPiR4 linuxPackages_frankw_6_12_bananaPiR4 ubootBananaPiR4;
  inherit (pine64rock64) ubootRock64 ubootRock64v2;
  inherit (raspberrypi) ubootRaspberryPi4 raspberryPiFirmware;
  inherit (orangepi5) ubootOrangePi5 ubootOrangePi5b;
}
