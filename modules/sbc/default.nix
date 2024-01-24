{ config
, lib
, options
, pkgs
, ...
}:
let
  cfg = config.sbc;
in
{
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
      type = types.enum [ "99.99" "0.1" ];
      default = "99.99";
      description = mdDoc ''
        Configuration version used on generated system.
        Used to set certain defaults to maintain bootable system.

        Should be set to the latest version when producing new boot images.
        Should be set to match version of image used to bootstrap system.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = if cfg.version == "99.99" then [
      ''
        config.sbc.version is unset, breaking config changes may occur that that
        result in boot failure, requring manual intervention with UART.

        Should be set to match version that generated bootstrap image.
      ''
    ] else [];

    # There doesn't appear to be a clean way to get "self", this flake, into
    # the args passed to modules.  Making users set specialArgs on top of
    # adding us as a module is simply too much.  It's messy, and it would be
    # error prone.  This gets our pkgs into args as sbcPkgs.
    _module.args = {
      sbcPkgs = pkgs.callPackage ../../pkgs { };
      sbcLibPath = ../../lib;
    };

    zramSwap.enable = lib.mkDefault true;

    nix.settings.auto-optimise-store = lib.mkDefault true;
  };
}
