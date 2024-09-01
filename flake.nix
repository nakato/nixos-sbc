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
    inherit (_lib) bootstrapSystem forAllSystems supportedBuildSystems supportedHostSystems;

    mkNixosConfigurations = {buildSystem ? null}: let
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
            modules =
              [self.nixosModules.boards.${system.manufacturer}.${system.model}]
              ++ (
                if buildSystem == null
                then []
                else [
                  {
                    nixpkgs.buildPlatform.system = buildSystem;
                  }
                ]
              );
          };
        })
        systems);
    in
      mkNixOsConfigurations;
  in {
    # Exposed for build tooling
    inherit _lib;

    formatter = forAllSystems (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );

    packages = forAllSystems (system:
      (
        if builtins.elem system supportedHostSystems
        then
          (
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
              import ./pkgs {inherit pkgs;}
          )
        else {}
      )
      // (
        if builtins.elem system supportedBuildSystems
        then
          (
            let
              nixosCrossConfigurations = mkNixosConfigurations {buildSystem = system;};
            in
              lib.mapAttrs' (name: value: lib.nameValuePair "sdImage-${name}" value.config.system.build.sdImage)
              nixosCrossConfigurations
          )
        else {}
      ));

    nixosModules = import ./modules;
    # deviceBuilder is an unstable API.  I'm throwing it in quickly
    # to unblock my usage.
    deviceBuilder = {
      rtc.ds3231 = import ./lib/devices/rtc/ds3231/create.nix;
    };

    nixosConfigurations = mkNixosConfigurations {};
  };
}
