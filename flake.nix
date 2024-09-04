{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib;

    _lib = import ./lib {
      inherit nixpkgs lib self;
    };
    inherit (_lib) forAllSystems forSupportedHostSystems;

    mkNixosConfigurations = let
      devices = [
        {
          manufacturer = "bananapi";
          model = "bpir3";
        }
        {
          manufacturer = "bananapi";
          model = "bpir4";
        }
        {
          manufacturer = "pine64";
          model = "rock64v2";
        }
        {
          manufacturer = "pine64";
          model = "rock64v3";
        }
        {
          manufacturer = "raspberrypi";
          model = "rpi4";
        }
        {
          manufacturer = "xunlong";
          model = "opi5b";
        }
      ];

      mkNixosConfigurations = builtins.listToAttrs (builtins.map
        (device: {
          name = "${device.manufacturer}-${device.model}";
          value = lib.nixosSystem {
            system =
              if device ? system
              then device.system
              else "aarch64-linux";
            modules =
              [
                self.nixosModules.default
                self.nixosModules.boards.${device.manufacturer}.${device.model}
                {
                  sbc.bootstrap.initialBootstrapImage = true;
                  sbc.version = "0.3";
                }
              ]
              ++ (lib.optionals (device ? extraModules) device.extraModules);
          };
        })
        devices);
    in
      mkNixosConfigurations;
  in {
    # Exposed for build tooling
    inherit _lib;

    formatter = forAllSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );

    packages = forSupportedHostSystems (system: import ./pkgs {pkgs = nixpkgs.legacyPackages.${system};});

    nixosModules = import ./modules;
    # deviceBuilder is an unstable API.  I'm throwing it in quickly
    # to unblock my usage.
    deviceBuilder = {
      rtc.ds3231 = import ./lib/devices/rtc/ds3231/create.nix;
    };

    nixosConfigurations = mkNixosConfigurations;
  };
}
