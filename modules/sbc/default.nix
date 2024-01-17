{ config
, lib
, options
, pkgs
, ...
}:
let
  cfg = config.sbc;
in
{
  options.sbc = with lib; {
    enable = mkEnableOption "Include SBC configuration";
  };

  config = lib.mkIf cfg.enable {
  };
}
