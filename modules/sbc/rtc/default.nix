{ config
, lib
, options
, pkgs
, ...
}:
let
  cfg = config.sbc.rtc;
  rtc = import ../../../lib/board/spec/rtc.nix;
in
{
  options.sbc.rtc = with lib; {
    devices = mkOption {
      type = types.listOf (types.submodule uart);
      description = lib.mdDoc ''
        List of RTC devices to use.  While having more than one is valid, you
        likely only want one.
      '';
    };
  };

  config = lib.mkIf config.sbc.enable {
    assertions = [
      {
        assertion = builtins.any (attr: !attr.enable) cfg.devices;
        message = ''
          An RTC device disabled in DT cannot be set as the devices RTC.
          Enable the device, or override the sbc.rtc.devices list.
        '';
      }
    ];
  };
}
