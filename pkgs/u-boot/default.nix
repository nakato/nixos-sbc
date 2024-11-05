{
  buildUBoot,
  fetchpatch,
  lib,
  ...
}: let
  sbcExtraConfig = ''
    CONFIG_AUTOBOOT=y
    CONFIG_BOOTDELAY=1
    CONFIG_USE_BOOTCOMMAND=y
    # Use bootstd and bootflow over distroboot for extlinux support
    CONFIG_BOOTSTD_DEFAULTS=y
    CONFIG_BOOTSTD_FULL=y
    CONFIG_CMD_BOOTFLOW_FULL=y
    CONFIG_BOOTCOMMAND="bootflow scan -lb"
    CONFIG_DEVICE_TREE_INCLUDES="nixos-mmcboot.dtsi"
    # Disable saving env, it isn't tested and probably doesn't work.
    CONFIG_ENV_IS_NOWHERE=y
    CONFIG_LZ4=y
    CONFIG_BZIP2=y
    CONFIG_ZSTD=y
    # Boot on root ext4 support
    CONFIG_CMD_EXT4=y
    # Boot on root btrfs support
    CONFIG_FS_BTRFS=y
    CONFIG_CMD_BTRFS=y
  '';
  sbcExtraPatches = [
    ./nix-version.patch
  ];
in {
  buildSBCUBoot = args:
    (buildUBoot (
      (removeAttrs args ["postPatch" "extraPatches"])
      // {
        extraConfig = sbcExtraConfig + (lib.optionalString (args ? extraConfig) args.extraConfig);
      }
    ))
    .overrideAttrs (oldAttrs: {
      # No RPi patches
      patches = (lib.optionals (args ? extraPatches) args.extraPatches) ++ sbcExtraPatches;
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ (lib.optionals (args ? extraNativeBuildInputs) args.extraNativeBuildInputs);
      postPatch = oldAttrs.postPatch + (lib.optionalString (args ? postPatch) args.postPatch);
    });

  patchSBCUBoot = pkg:
    pkg.overrideAttrs (oldAttrs: {
      extraConfig = (lib.optionalString (oldAttrs ? extraConfig) oldAttrs.extraConfig) + sbcExtraConfig;
      patches = oldAttrs.patches ++ sbcExtraPatches;
    });
}
