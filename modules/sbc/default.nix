{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.sbc;
in {
  imports = [
    ./board
    ./boot
    ./bootstrap
    ./filesystem.nix
    ./wireless
  ];

  options.sbc = with lib; {
    enable = mkEnableOption "Include SBC configuration";

    version = mkOption {
      type = types.enum ["99.99" "0.2" "0.1"];
      default = "99.99";
      description = mdDoc ''
        Configuration version used on generated system.
        Used to set certain defaults to maintain bootable system.

        Should be set to the latest version when producing new boot images.
        Should be set to match version of image used to bootstrap system.
      '';
    };

    suppressVendorKernelWarning = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Suppress the warning that occurs when using a vendored (not-upstream)
        Linux kernel.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = []
      ++ lib.optionals (cfg.version == "99.99") [
        ''
          config.sbc.version is unset, breaking config changes may occur that
          result in boot failure, requring manual intervention with UART.

          Should be set to match version that generated bootstrap image.
        ''
      ]
      ++ lib.optionals (!cfg.suppressVendorKernelWarning && (config.boot.kernelPackages.kernel.extraMeta.vendorKernel or false)) [
        ''
          This device uses a vendor kernel, vendor kernels commonly use
          different names for various nodes in the device-tree.
          If you are not manually applying device-tree overlays or somehow
          relying on DT node names in userspace, which is unlikely,
          you can ignore this warning.
          To suppress this warning set `sbc.suppressVendorKernelWarning` to
          `true`.
          Note that this kernel will be dropped when upstream support for the
          kernel becomes available.
        ''
      ];

    # There doesn't appear to be a clean way to get "self", this flake, into
    # the args passed to modules.  Making users set specialArgs on top of
    # adding us as a module is simply too much.  It's messy, and it would be
    # error prone.  This gets our pkgs into args as sbcPkgs.
    _module.args = {
      sbcPkgs = pkgs.callPackage ../../pkgs {};
      sbcLibPath = ../../lib;
    };

    zramSwap.enable = lib.mkDefault true;

    nix.settings.auto-optimise-store = lib.mkDefault true;
  };
}
