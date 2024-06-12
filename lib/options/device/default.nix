{
  lib,
  pkgs,
  sbcLibPath,
  ...
}: {
  inherit (pkgs.callPackage ./device.nix {}) baseDevice;
  inherit (pkgs.callPackage ./dtoverlay.nix {inherit sbcLibPath;}) dtOverlayMethods getDTOverlays;
  inherit (pkgs.callPackage ./modules.nix {}) moduleMethods getEnableKernelModules getDisableKernelModules;
}
