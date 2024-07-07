{
  config,
  lib,
  options,
  ...
}: let
  cfg = config.sbc.boot.bootloader;
in {
  options.sbc.boot.bootloader = with lib; {
    manage = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        If you are doing something custom and don't want the default
        configuration for a device you can disable this.
      '';
    };

    backend = mkOption {
      type = types.enum ["uboot"];
      default = "uboot";
      description = lib.mdDoc ''
        The type of bootloader in use.  Used to configure other settings.
        Currently only uboot is supported.
      '';
    };
  };

  config = lib.mkIf (config.sbc.enable && cfg.manage && cfg.backend == "uboot") {
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    # gzip is known safe; bz2, lzma and lz4 should work as well, but not zstd.
    boot.initrd.compressor = lib.mkDefault "gzip";
  };
}
