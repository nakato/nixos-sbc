{config, lib, ...}: with lib;
let
  i2cDevice = import ./device.nix;
in
{
  options = {
    sbc.board.i2c.devices = mkOption {
      type = types.nullOr (types.attrsOf (types.submodule i2cDevice));
    };
  };
}
