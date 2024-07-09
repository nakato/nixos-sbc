{
  nixpkgs,
  self,
}: rec {
  forSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f system);

  forAllSystems = forSystems (builtins.attrNames nixpkgs.legacyPackages);

  supportedSystems = ["aarch64-linux" "riscv64-linux"];
  forSupportedSystems = forSystems supportedSystems;

  bootstrapSystem = {
    modules,
    system ? "aarch64-linux",
    ...
  } @ config:
    nixpkgs.lib.nixosSystem (
      config
      // {
        inherit system;
        modules =
          modules
          ++ [
            self.nixosModules.default
            {
              sbc.bootstrap.initialBootstrapImage = true;
              sbc.version = "0.2";
            }
          ];
      }
    );
}
