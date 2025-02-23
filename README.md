# NixOS-SBC

NixOS-SBC aims to provide boot images for various Single Board Computers,
provide patched u-boot and kernel if required, and provide an abstraction
to managing add-on hardware.


## Work in progress

This is currently a work in progress.

Currently included:
 * Packages
 * Image creation
   * Single BTRFS partition with subvolumes (default)
   * Single BTRFS partition
   * Single ext4 partition
 * Cachix binary cache

Alpha (Functional, but subject to change):
 * Nix board definitions
 * Nix device definitions


## Supported Single Board Computer Quick Reference

For full details, see board page.  Every SBC in existance has quirks, some bigger some smaller, see the board Info pages for known quirks and issues.
Info pages are currently not standarised and may not be complete.

| Board Manufacturer | Model           | Bootable | Kernel      | Have SBC | Board page |
| ------------------ | --------------- | -------- | ----------- | -------- | ---------- |
| BananaPi           | BPiR3           | Yes      | Upstream¹˒² | Yes      | [Info](/modules/boards/bananapi/bpir3/info.md) |
| BananaPi           | BPiR4           | Yes      | Vendor¹     | Yes⁴     | [Info](/modules/boards/bananapi/bpir4/info.md) |
| Pine64             | Rock64v2        | Yes      | Upstream    | Yes      | [Info](/modules/boards/pine64/rock64/info.md) |
| Pine64             | Rock64v3        | Yes      | Upstream    | Yes      | [Info](/modules/boards/pine64/rock64/info.md) |
| RaspberryPi        | RPi4            | Yes      | Upstream    | Yes      | [Info](/modules/boards/raspberrypi/rpi4/info.md) |
| Xunlong            | OrangePi 5      | Untested | Upstream    | No       | [Info](/modules/boards/xunlong/opi5/info.md) |
| Xunlong            | OrangePi 5B     | Yes      | Upstream³   | Yes      | [Info](/modules/boards/xunlong/opi5/info.md) |

* ¹ Requires custom build
* ² Has minor patching
* ³ DTB is out-of-tree
* ⁴ Do not own WiFi card

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
    nixos-sbc.url = "github:nakato/nixos-sbc/master";
  };

  outputs = { self, nixpkgs, nixos-sbc }: {
    nixosConfigurations = {
      my-sbc = nixpkgs.lib.nixosSystem {
        modules = [
          nixos-sbc.nixosModules.default
          # Ex: nixos-sbc.nixosModules.boards.bananapi.bpir3
          nixos-sbc.nixosModules.boards.<BOARD MFG>.<BOARD MODEL>
          {
            sbc.version = "0.3";

            # User config, networking, etc
          }
        ];
      };
      x86-operator = nixpkgs.lib.nixosSystem {
        modules = [
          # If foreign architecture is performing "nix build"/"nixos-rebuild" commands targeting SBC
          # and binary cache usage is desired it must be included on host performing evaluation.
          nixos-sbc.nixosModules.cache
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

Bootstrap images can be used when you want to produce a bootable system
without pre-customising the devices configuration.  These images are best
built on the same architecture as the target system to take advantage of
caching; however, they can be cross-compiled if required.

`nix build "github:nakato/nixos-sbc#sdImages.${buildHostArchitecture}.sdImage-${manufacturer}-${model}"`
For example:
`nix build "github:nakato/nixos-sbc#sdImages.x86_64-linux.sdImage-bananapi-bpir4"`

Once the image is provisioned onto the SD card, the device will DHCP on all
available interfaces.  Log into the root user with the password
`SBCDefaultBootstrapPassword`, then change the password with `passwd`.
