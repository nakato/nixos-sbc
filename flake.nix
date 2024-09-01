{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    _lib = import ./lib {
      inherit nixpkgs self;
      lib = nixpkgs.lib;
    };
    inherit (_lib) bootstrapSystem forAllSystems forSupportedSystems;
  in {
    # Exposed for build tooling
    inherit _lib;

    formatter = forAllSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );

    packages = forSupportedSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        import ./pkgs {inherit pkgs;}
    );

    nixosModules = import ./modules;
    # deviceBuilder is an unstable API.  I'm throwing it in quickly
    # to unblock my usage.
    deviceBuilder = {
      rtc.ds3231 = import ./lib/devices/rtc/ds3231/create.nix;
    };

    nixosConfigurations = let
      systems = [
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

      mkNixOsConfigurations = builtins.listToAttrs (builtins.map
        (system: {
          name = "${system.manufacturer}-${system.model}";
          value = bootstrapSystem {
            modules = [self.nixosModules.boards.${system.manufacturer}.${system.model}];
          };
        })
        systems);
    in
      mkNixOsConfigurations;
  };
}
