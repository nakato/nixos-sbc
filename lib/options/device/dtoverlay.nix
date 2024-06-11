{sbcLibPath}: {
  dtOverlayOptions = {
    config,
    dtStatus,
    globalConfig,
    lib,
    name,
    ...
  }:
    with lib; {
      options = {
        dtOverlay = mkOption {
          type = types.submoduleWith {
            modules = [(sbcLibPath + "/device-tree/simple-overlay.nix")];
            specialArgs = {
              inherit globalConfig;
              target = name;
              status = dtStatus;
            };
          };
          default = {};
        };
      };
    };
}
