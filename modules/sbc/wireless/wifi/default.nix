{ config
, lib
, ...}:
let
  cfg = config.sbc.wireless.wifi;
in
{
  options.sbc.wireless.wifi = with lib; {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        If enabled, SBC will be configured to enable WiFi hardware, if it has it.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = [ "rfkill" "cfg80211" ];

    hardware.wirelessRegulatoryDatabase = lib.mkForce true;
  };
}
