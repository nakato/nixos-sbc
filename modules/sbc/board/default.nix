{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.sbc.board;
in {
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

    sbc.board.vendor = mkOption {
      type = types.str;
      description = lib.mdDoc "Board manufacturer";
    };

    sbc.board.model = mkOption {
      type = types.str;
      description = lib.mdDoc "Board model";
    };

    sbc.board.dtRoot = mkOption {
      type = types.str;
      description = lib.mdDoc "The string used as the compatible line in overlays";
    };
  };

  config = lib.mkIf config.sbc.enable {
    sbc.board.name = lib.mkDefault "${cfg.vendor} ${cfg.model}";
  };
}
