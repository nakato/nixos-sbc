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
  options.sbc = with lib; {
    enable = mkEnableOption "Include SBC configuration";
  };

  config = lib.mkIf cfg.enable {
    # There doesn't appear to be a clean way to get "self", this flake, into
    # the args passed to modules.  Making users set specialArgs on top of
    # adding us as a module is simply too much.  It's messy, and it would be
    # error prone.  This gets our pkgs into args as sbcPkgs.
    _module.args = { sbcPkgs = pkgs.callPackage ../../pkgs { }; };
  };
}
