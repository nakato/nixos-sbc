{ config, lib, ... }: with lib;
let
  wifi = import ./wifi.nix;
  uart = import ./uart.nix;
  i2c = import ./i2c.nix;
  rtc = import ./rtc.nix;
in
{
  options = {
    name = mkOption {
      type = types.str;
      description = lib.mdDoc "A friendly name for the board";
    };

    dtRoot = mkOption {
      type = types.str;
      description = lib.mdDoc "The string used as the compatible line in overlays";
    };

    wifi = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule wifi));
    };

    uart = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule uart));
    };

    i2c = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule i2c));
    };

    rtc = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule rtc));
    };
  };
}
