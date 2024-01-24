{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self
    , nixpkgs
    , ...
  }:
  let
    systems = [ "aarch64-linux" "riscv64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      import ./pkgs { inherit pkgs; }
    );

    nixosModules = import ./modules;

    nixosConfigurations = {
      bananapi-bpir3 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          self.nixosModules.default
          self.nixosModules.boards.bananapi.bpir3
          {
            sbc.bootstrap.initialBootstrapImage = true;
            sbc.version = "0.1";
          }
        ];
      };
    };
  };
}
