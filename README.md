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
 * Image creation
   * Single BTRFS partition with subvolumes (default)
   * Single BTRFS partition
   * Single ext4 partition

Alpha (Functional, but subject to change):
 * Nix board definitions
 * Nix device definitions

Work in progress:
 * Cachix


## Single Board Computers

| Board Manufacturer | Model           | Bootable |
| ------------------ | --------------- | -------- |
| BananaPi           | BPiR3           | ✓        |
| Pine64             | Rock64          | ✓        |
| RaspberryPi        | RPi4            | ✓        |


| Icon | Description  |
| ---- | ------------ |
| ✓    | Supported    |
| ✗    | Missing      |
| ○    | Not Required |


## Supported Devices

Not all devices are supported on all boards.

| Device Class | Device | Requirements | Documentation |
| ------------ | ------ | ------------ | ------------- |
| RTC          | DS3231 | i2c          | [Link](./lib/devices/rtc/ds3231/README.md) |


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
          # Ex: nixos-sbc.nixosModules.boards.bananapi.bpir3
          nixos-sbc.nixosModules.boards.<BOARD MFG>.<BOARD MODEL>
          {
            sbc.version = "0.2";

            # User config, networking, etc
          }
        ];
      };
    };
  };
}
```

Produce your customised image with:
```
nix build '/path/to/your-flake-repo#nixosConfigurations.hostname.config.system.build.sdImage'
```

## Bootstrap images

Bootstrap images are provided for use when a board of the same architecture
as the target, with nix installed, is not available to produce a pre-customised
image.

Once the image is provisioned onto the SD card, the device will DHCP on all
available interfaces.  Log into the root user with the password
`SBCDefaultBootstrapPassword`, then change the password with `passwd`.
