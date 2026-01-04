{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.sbc.bootstrap.initialBootstrapImage {
    sbc.wireless.wifi.enable = false;
  };
}
