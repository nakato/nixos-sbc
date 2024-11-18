{
  config,
  lib,
  ...
}: {
  config = lib.mkIf (config.sbc.enable) {
    # Most SBCs do not have TPMs and minimal kernels will thus not include
    # modules. Disable TPM hard dependency in systemd based stage 1.
    boot.initrd.systemd.tpm2.enable = lib.mkDefault false;
  };
}
