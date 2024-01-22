{ config
, lib
, ...
}:
let
  cfg = config.sbc.filesystem;
in
{
  options.sbc.filesystem = with lib; {
    useDefaultLayout = mkOption {
      type = types.enum [ "ext4" false ];
      default = false;
      description = mdDoc ''
        When a pre-built SD image is used, the filesystem layout will be
        known to us, so by enabling the use of the default layout you do
        not need to specify it yourself.

        Options are false or "ext4".
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.sbc.enable && cfg.useDefaultLayout == "ext4") {
      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/0b5e3376-c7e9-4284-9514-9c3b51244f19";
          fsType = "ext4";
        };
      };
    })
  ];
}
