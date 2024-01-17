# NixOS-SBC

NixOS-SBC aims to provide boot images for various Single Board Computers,
provide patched u-boot and kernel if required, and provide an abstraction
to managing add-on hardware.


## Support

Providing support will allow me to spend more time on this as well as aquire
new and interesting devices.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/nakatoio)


## Work in progress

This is currently a work in progress.

Currently included:
 * Packages

Work in progress:
 * Cachix
 * SD-Card boot images
 * Nix board definitions
 * Nix device definitions


## Single Board Computers

| Board Manufacturer | Model           |
| ------------------ | --------------- |
| BananaPi           | BPiR3           |


## Supported Devices

Not all devices are supported on all boards.

| Device Class | Device | Requirements |
| ------------ | ------ | ------------ |
| RTC          | DS3231 | i2c          |


## Setup

### Using nix flakes

```nix
{
  description = "NixOS configuration with flakes";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-sbc = {
      url = "github:nakato/nixos-sbc/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-sbc }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        modules = [
          nixos-sbc.nixosModules.default
        ];
      };
    };
  };
}
```