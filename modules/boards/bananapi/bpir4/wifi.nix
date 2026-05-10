{
  config,
  lib,
  ...
}: let
  cfg = config.sbc.board.bananapi.bpir4;
in {
  options.sbc.board.bananapi.bpir4 = with lib; {
  };

  config = lib.mkMerge [

    # FIXME: If config.sbc.wireless.wifi.enable is false, should we be heavy-handed
    #        and disable the PCIe ports?

    (lib.mkIf config.sbc.wireless.wifi.enable {
      assertions = [
        {
          assertion = config.sbc.wireless.wifi.acceptRegulatoryResponsibility;
          message = ''
            WiFi hardware with generic eeprom data has been enabled, but acceptance
            of regulatory responsibility has not been set.

            To enable WiFi hardware, you must explicitly set
            `config.sbc.wireless.wifi.acceptRegulatoryResponsibility`, which means
            you understand your responsibility in ensuring the device operates
            within the requirements of your regulatory domain.
            Ex: Power, gain, radar detection, etc.

            You may fully disable the WiFi hardware with
            `config.sbc.board.wifi.devices.wifi.enable = false`.
          '';
        }
      ];

      hardware.enableRedistributableFirmware = true;

      hardware.deviceTree.overlays = lib.mkIf config.sbc.wireless.wifi.enable [
        {
          name = "BPiR4EnableWifi";
          dtsFile = ./mt7988a-bananapi-bpi-r4-wirless.dts;
        }
      ];
    })
  ];
}
