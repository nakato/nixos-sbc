component: target: compatable: {
  name = "nixos-sbc-ds3231-${component}-overlay";
  dtsText = ''
    /dts-v1/;
    /plugin/;

    / {
      compatible = "${compatable}";

      fragment@0 {
        target = <${target}>;
        __overlay__ {
          #address-cells = <1>;
          #size-cells = <0>;
          ds3231: rtc@68 {
            compatible = "maxim,ds3231";
            reg = <0x68>;
            status = "okay";
          };
        };
      };
    };
  '';
}
