{config, lib, ...}: with lib; {
  options = {
    status = mkOption {
      type = types.enum [ "disabled" "okay" "always" ];
      description = mdDoc "Status of hardware in DT";
    };

    enable = mkOption {
      type = types.bool;
      description = mdDoc "Disable or enable hardware in device tree";
    };
  };

  config = {
    enable = mkDefault (config.status != "disabled");
  };
}
