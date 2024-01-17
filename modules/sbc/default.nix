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

    initialBootstrapImage = mkOption {
      type = types.bool;
      default = false;
      visible = false;
      description = ''
        This option is used to change defaults for producing bootstrap images.

        For example, setting WiFi as disabled for generic bootstrap images while
        leaving it as enabled for user use.  This is so we can bubble the regulatory
        info up as a default-error to the user so they don't get supprised by the
        wifi being missing once they build their own system.
      '';
    };

    acceptRegulatoryResponsibility = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Assert that you understand you are responsible for ensuring your
        devices abide by any regulatory domains relevant to your location.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # There doesn't appear to be a clean way to get "self", this flake, into
    # the args passed to modules.  Making users set specialArgs on top of
    # adding us as a module is simply too much.  It's messy, and it would be
    # error prone.  This gets our pkgs into args as sbcPkgs.
    _module.args = { sbcPkgs = pkgs.callPackage ../../pkgs { }; };
  };
}
