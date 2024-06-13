filter: {config, ...}: let
  inherit (filter {inherit config;}) i2cConfig;
in {
  # Remove 'status = ""' from the RTC overlay, and demote this to warning.
  assertions = [
    {
      assertion = i2cConfig.enable;
      message = ''
        Enabling RTC devices on a disabled i2c bus will have no effect.
      '';
    }
  ];

  sbc.board.rtc.devices.ds3231 = {
    status = "disabled";
    enable = true;
    enableMethod.dtOverlay = {
      enable = true;
      target = i2cConfig.dtTarget;
      extraOverlayText = ''
        #address-cells = <1>;
        #size-cells = <0>;
        ds3231: rtc@68 {
          compatible = "maxim,ds3231";
          reg = <0x68>;
          status = "okay";
        };
      '';
    };
    enableMethod.moduleLoad = ["rtc_ds1307"];
  };
}
