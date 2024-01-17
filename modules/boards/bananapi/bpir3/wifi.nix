{ config
, lib
, ...}:
let
  cfg = config.sbc.board.bananapi.bpir3;
in
{
  options.sbc.board.bananapi.bpir3 = with lib; {
    enableWiFi = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        If enabled, the device will be configured to enable WiFi hardware.
      '';
    };
    enableWiFiTrainingData = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        If enabled, the WiFi training data provided by Mediatek and taken from
        OpenWRT will be applied as a DTOverlay enabling WiFi functionality.

        You must enable 'config.sbc.acceptRegulatoryResponsibility' for this to work.

        If you have training data in flash or are providing it via other means, you
        can disable this.  WiFi will not function without training data.
      '';
    };
  };

  config =
    lib.mkMerge [
      (lib.mkIf config.sbc.initialBootstrapImage {
        sbc.board.bananapi.bpir3.enableWiFi = false;
      })
      (lib.mkIf cfg.enableWiFi {
        assertions = [
          {
            assertion = config.sbc.board.bananapi.bpir3.enableWiFiTrainingData -> config.sbc.acceptRegulatoryResponsibility;
            message = ''
              To enable WiFi you must explicitly set 'config.sbc.acceptRegulatoryResponsibility',
              stating that you understand your resposibility in ensuring the device operates
              within the requirements of your regulatory domain.

              If you wish to disable wifi support, you may do so by setting
              'config.sbc.board.bananapi.bpir3.enableWiFi' to false'';
          }
        ];

        boot.initrd.kernelModules = [ "rfkill" "cfg80211" "mt7915e" ];

        hardware.enableRedistributableFirmware = true;
        hardware.wirelessRegulatoryDatabase = lib.mkForce true;

        hardware.deviceTree.overlays = lib.mkIf config.sbc.board.bananapi.bpir3.enableWiFiTrainingData [
          {
            name = "BananaPi R3 WiFi Training Data";
            dtsFile = ./mt7986a-bananapi-bpi-r3-wirless.dts;
          }
        ];
      })
    ];
}
