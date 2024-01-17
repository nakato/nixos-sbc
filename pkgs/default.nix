{ pkgs }:
let
  bananaPiR3 = pkgs.callPackage ./bananaPiR3 { };
in
{
  inherit (bananaPiR3) armTrustedFirmwareMT7986 linuxPacakges_6_7_bananaPiR3 ubootBananaPiR3;
}
