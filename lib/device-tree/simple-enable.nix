component: target: compatable: {
  name = "nixos-sbc-${component}-overlay";
  dtsText = ''
    /dts-v1/;
    /plugin/;

    / {
      compatible = "${compatable}";

      fragment@0 {
        target = <${target}>;
        __overlay__ {
          status = "okay";
        };
      };
    };
  '';
}
