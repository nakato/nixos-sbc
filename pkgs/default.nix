{pkgs}: let
  bananaPiR3 = pkgs.callPackage ./bananaPiR3 {};
  pine64rock64 = pkgs.callPackage ./pine64rock64 {};
  raspberrypi = pkgs.callPackage ./raspberrypi {};
in {
  inherit (bananaPiR3) armTrustedFirmwareMT7986 linuxPackages_latest_bananaPiR3 linuxPackages_6_9_bananaPiR3 ubootBananaPiR3;
  inherit (pine64rock64) ubootRock64 ubootRock64v2;
  inherit (raspberrypi) ubootRaspberryPi4 raspberryPiFirmware;
}
