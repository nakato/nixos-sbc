{ config
, lib
, ...
}:
with lib;
{
  imports = [
    ./i2c
    ./uart
    ./wifi
    ./rtc
  ];

  options = {
    sbc.board.name = mkOption {
      type = types.str;
      description = lib.mdDoc "A friendly name for the board";
    };

    sbc.board.dtRoot = mkOption {
      type = types.str;
      description = lib.mdDoc "The string used as the compatible line in overlays";
    };
  };
}
