i2c: {
  status = "disabled";
  enable = true;
  enableMethod.dtOverlay = ./dt.nix;
  enableMethod.moduleLoad = [ "rtc_ds1307" ];
}
