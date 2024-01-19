{config, lib, ...}: with lib;
let
  wifiDevice = import ./device.nix;
in
{
  options = {
    sbc.board.wifi.devices = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule wifiDevice));
    };
  };
}
