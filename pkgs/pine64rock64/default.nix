{
  patchSBCUBoot,
  dtc,
  fetchurl,
  fetchpatch,
  ubootRock64,
  ubootRock64v2,
  ...
}: let
  overrideUbootAttrs = oldAttrs: {
    postPatch =
      oldAttrs.postPatch
      + ''
        cp ${./mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
      '';
    extraConfig =
      oldAttrs.extraConfig
      + ''
        CONFIG_DEVICE_TREE_INCLUDES="nixos-mmcboot.dtsi"
      '';
  };
in {
  ubootRock64 = (patchSBCUBoot ubootRock64).overrideAttrs overrideUbootAttrs;
  ubootRock64v2 = (patchSBCUBoot ubootRock64v2).overrideAttrs overrideUbootAttrs;
}
