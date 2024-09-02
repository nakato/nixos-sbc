# To prevent this from being included, as is the default with
# "sbc.version >= 0.3" set "config.sbc.binaryCache.enable = false".
#
# To include on a non-sbc platform, such as an x86_64 host configured
# with remote building  add "nixos-sbc.nixosModules.cache" to the modules
# list to include this and rebuild the system so it is included in nix.conf.
{
  nix = {
    settings = {
      substituters = ["https://nixos-sbc.cachix.org/"];
      trusted-public-keys = ["nixos-sbc.cachix.org-1:XMK0HnQmmGIt1lYy1y+JsxLpHVaSTRRWvd6T6cU+I2M="];
    };
  };
}
