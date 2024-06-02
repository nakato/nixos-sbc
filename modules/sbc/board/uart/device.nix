{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    status = mkOption {
      type = types.enum ["disabled" "okay" "always"];
      description = mdDoc "Status of hardware in DT";
    };

    enable = mkOption {
      type = types.bool;
      description = mdDoc "Disable or enable hardware in device tree";
    };

    deviceName = mkOption {
      type = types.str;
      description = mdDoc "Name of UART device in Linux";
    };

    baud = mkOption {
      type = types.int;
      description = mdDoc "Default baud-rate of the hardware, used by software";
    };

    console = mkOption {
      type = types.bool;
      description = mdDoc "If true, device will be configured as a console during boot";
    };
  };

  config = {
    enable = mkOptionDefault (config.status != "disabled");
  };
}
