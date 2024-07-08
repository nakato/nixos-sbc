{pkgs}: let
  u-boot = pkgs.callPackage ./u-boot {};
  pkgsArgs = {inherit (u-boot) buildSBCUBoot patchSBCUBoot;};

  bananaPiR3 = pkgs.callPackage ./bananaPiR3 pkgsArgs;
  pine64rock64 = pkgs.callPackage ./pine64rock64 pkgsArgs;
  raspberrypi = pkgs.callPackage ./raspberrypi pkgsArgs;
  orangepi5 = pkgs.callPackage ./orangepi5 pkgsArgs;
in {
  inherit (bananaPiR3) armTrustedFirmwareMT7986 linuxPackages_latest_bananaPiR3 linuxPackages_6_9_bananaPiR3 ubootBananaPiR3 linuxPackages_6_9_bananaPiR3_minimal;
  inherit (pine64rock64) ubootRock64 ubootRock64v2;
  inherit (raspberrypi) ubootRaspberryPi4 raspberryPiFirmware;
  inherit (orangepi5) ubootOrangePi5 ubootOrangePi5b orangePi5bDTBs;
}
