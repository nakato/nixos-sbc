{ config, lib, ... }: with lib;
let
  wifi = {config, ...}: {
    options = {
      status = mkOption {
        type = types.enum [ "disabled" "okay" "always" ];
        description = lib.mdDoc "Default status of hardware in DT";
      };

      enable = mkOption {
        type = types.bool;
        description = lib.mdDoc "Disable or enable hardware in device tree";
      };
    };
    config = {
      enable = lib.mkDefault (config.status != "disabled");
    };
  };

  uart = {config, ...}: {
    options = {
      status = mkOption {
        type = types.enum [ "disabled" "okay" "always" ];
        description = lib.mdDoc "Status of hardware in DT";
      };

      enable = mkOption {
        type = types.bool;
        description = lib.mdDoc "Disable or enable hardware in device tree";
      };

      deviceName = mkOption {
        type = types.str;
        description = lib.mdDoc "Name of UART device in Linux";
      };

      baud = mkOption {
        type = types.int;
        description = lib.mdDoc "Default baud-rate of the hardware, used by software";
      };
    };
    config = {
      enable = lib.mkDefault (config.status != "disabled");
    };
  };

  i2c = {config, ...}: {
    options = {
      status = mkOption {
        type = types.enum [ "disabled" "okay" "always" ];
        description = lib.mdDoc "Status of hardware in DT";
      };

      enable = mkOption {
        type = types.bool;
        description = lib.mdDoc "Disable or enable hardware in device tree";
      };
    };
    config = {
      enable = lib.mkDefault (config.status != "disabled");
    };
  };

  rtc = {config, ...}: {
    options = {
      status = mkOption {
        type = types.enum [ "disabled" "okay" "always" ];
        description = lib.mdDoc "Status of hardware in DT";
      };

      enable = mkOption {
        type = types.bool;
        description = lib.mdDoc "Disable or enable hardware in device tree";
      };
    };
    config = {
      enable = lib.mkDefault (config.status != "disabled");
    };
  };
in
{
  options = {
    name = mkOption {
      type = types.str;
      description = lib.mdDoc "A friendly name for the board";
    };

    dtRoot = mkOption {
      type = types.str;
      description = lib.mdDoc "The string used as the compatible line in overlays";
    };

    wifi = mkOption {
      type = types.attrsOf (types.submodule wifi);
    };

    uart = mkOption {
      type = types.attrsOf (types.submodule uart);
    };

    i2c = mkOption {
      type = types.attrsOf (types.submodule i2c);
    };

    rtc = mkOption {
      type = types.attrsOf (types.submodule rtc);
    };
  };
}
