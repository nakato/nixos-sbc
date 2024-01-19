{config, lib, ...}: with lib;
let
  rtcDevice = import ./device.nix;
in
{
  options = {
    sbc.board.rtc.devices = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule rtcDevice));
    };
  };
}
