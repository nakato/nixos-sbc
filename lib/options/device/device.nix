{lib, ...}:
with lib; {
  baseDevice = {
    config,
    name,
    ...
  }: {
    options = {
      dtTarget = mkOption {
        type = types.str;
        default = name;
      };

      status = mkOption {
        type = types.enum ["disabled" "okay" "always"];
        description = mdDoc ''
          Status of hardware in Device-Tree.
          "always" is a bad hack for things that exist without a status.
        '';
      };

      enable = mkOption {
        type = types.bool;
        description = mdDoc ''
          Describes the desired state of the hardware in the device-tree.
          Defaults to `true` if status is "okay" or "always".
          Defautls to `false if status is "disabled".
        '';
      };
    };
    config = {
      enable = mkOptionDefault (config.status != "disabled");
    };
  };
}
