{ ubootRock64
, ubootRock64v2
, ...}:
let
  ubootExtraConfig = ''
    CONFIG_AUTOBOOT=y
    CONFIG_BOOTDELAY=1
    CONFIG_USE_BOOTCOMMAND=y
    # Use bootstd and bootflow over distroboot for extlinux support
    CONFIG_BOOTSTD_DEFAULTS=y
    CONFIG_BOOTSTD_FULL=y
    CONFIG_CMD_BOOTFLOW_FULL=y
    # Big kernels
    # CONFIG_SYS_BOOTM_LEN=0x6000000
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
in
{
  ubootRock64 = ubootRock64.overrideAttrs (oldAttrs: {
    extraConfig = ubootExtraConfig;
  });
  ubootRock64v2 = ubootRock64v2.overrideAttrs (oldAttrs: {
    extraConfig = ubootExtraConfig;
  });
}
