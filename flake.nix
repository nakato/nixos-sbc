{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    _lib = import ./lib {inherit nixpkgs self;};
    inherit (_lib) bootstrapSystem forAllSystems forSupportedSystems;
  in {
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

    nixosConfigurations = {
      bananapi-bpir3 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.bananapi.bpir3
        ];
      };
      bananapi-bpir4 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.bananapi.bpir4
        ];
      };
      pine64-rock64v2 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.pine64.rock64v2
        ];
      };
      pine64-rock64v3 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.pine64.rock64v3
        ];
      };
      raspberrypi-rpi4 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.raspberrypi.rpi4
        ];
      };
      xunlong-opi5b = bootstrapSystem {
        modules = [
          self.nixosModules.boards.xunlong.opi5b
        ];
      };
    };
  };
}
