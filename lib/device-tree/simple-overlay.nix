{
  config,
  lib,
  globalConfig,
  target,
  status,
  ...
}: let
  mapRefList = l: builtins.concatStringsSep ", " (builtins.map (a: "<&${a}>") l);
in {
  options = with lib; {
    enable = mkEnableOption {};
    target = mkOption {
      type = types.str;
      default = target;
    };
    compatable = mkOption {
      type = types.str;
      default = globalConfig.sbc.board.dtRoot;
    };
    pinctrl-names = mkOption {
      default = null;
      type = types.nullOr types.str;
    };
    pinctrl-0 = mkOption {
      default = null;
      type = types.nullOr (types.listOf types.str);
    };
    extraOverlayText = mkOption {
      type = types.str;
      default = "";
    };
    dtOverlay = mkOption {
      type = types.attrs;
      default = {};
    };
  };

  config = {
    dtOverlay = {
      name = "nixos-sbc-${config.target}-overlay";
      dtsText = let
        pinctrlNames =
          if !(builtins.isNull config.pinctrl-names)
          then ''pinctrl-names = "${config.pinctrl-names}";''
          else "";
        pinctrl0 =
          if !(builtins.isNull config.pinctrl-0)
          then ''pinctrl-0 = ${mapRefList config.pinctrl-0};''
          else "";
      in ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "${config.compatable}";

          fragment@0 {
            target = <&${config.target}>;
            __overlay__ {
              status = "${status}";
              ${pinctrlNames}
              ${pinctrl0}
              ${config.extraOverlayText}
            };
          };
        };
      '';
    };
  };
}
