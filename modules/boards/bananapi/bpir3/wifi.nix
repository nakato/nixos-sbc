{
  config,
  lib,
  ...
}: let
  cfg = config.sbc.board.bananapi.bpir3;
in {
  options.sbc.board.bananapi.bpir3 = with lib; {
    enableWiFiTrainingData = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        If enabled, the WiFi training data provided by Mediatek and taken from
        OpenWRT will be applied as a DTOverlay enabling WiFi functionality.

        You must enable 'config.sbc.wireless.wifi.acceptRegulatoryResponsibility'
        for this to work.

        If you have training data in flash or are providing it via other means, you
        can disable this.  WiFi will not function without training data.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.sbc.board.wifi.devices.wifi.enable {
      warnings = lib.mkIf (!cfg.enableWiFiTrainingData) [
        ''
          BananaPi R3 WiFi hardware is enabled, however training data has not been enabled.
          The WiFi hardware will not function without training data being provided, this can be
          enabled with "config.sbc.board.bananapi.bpir3.enableWiFiTrainingData = true;"

          If another method of providing training data is working, document that and add an option
          to silence this warning.
        ''
      ];
      assertions = [
        {
          assertion = cfg.enableWiFiTrainingData -> config.sbc.wireless.wifi.acceptRegulatoryResponsibility;
          message = ''
            WiFi hardware with WiFi traning data has been enabled but acceptance of
            regulatory responsibility has not been set.

            To enable WiFi hardware with training data, you must explicitly set
            `config.sbc.wireless.wifi.acceptRegulatoryResponsibility`, which means
            you understand your responsibility in ensuring the device operates
            within the requirements of your regulatory domain.

            You may however choose to disable the WiFi training data with
            `config.sbc.board.bananapi.bpir3.enableWiFiTrainingData = false`,
            in which case the WiFi hardware will not function.  Or you may fully
            disable the WiFi hardware with
            `config.sbc.board.wifi.devices.wifi.enable = false`.
          '';
        }
      ];

      hardware.enableRedistributableFirmware = true;

      hardware.deviceTree.overlays = lib.mkIf config.sbc.board.bananapi.bpir3.enableWiFiTrainingData [
        {
          name = "BananaPi R3 WiFi Training Data";
          dtsFile = ./mt7986a-bananapi-bpi-r3-wirless.dts;
        }
      ];
    })
  ];
}
