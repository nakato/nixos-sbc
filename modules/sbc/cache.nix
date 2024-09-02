{
  config,
  lib,
  pkgs,
  ...
}: {
  options.sbc.binaryCache = with lib; {
    enable = mkOption {
      type = types.bool;
      description = mdDoc ''
        Controls if binary-cache for the nixos-sbc repository should be
        configured for nix daemon.

        Default(sbc.version >= 0.3): true
        Default(sbc.version < 0.3): false
      '';
    };
  };

  config = lib.mkMerge [
    {
      sbc.binaryCache.enable = lib.mkOptionDefault (
        if (lib.versionAtLeast config.sbc.version "0.3")
        then true
        else false
      );
    }
    (lib.mkIf config.sbc.binaryCache.enable (import ../cache.nix))
  ];
}
