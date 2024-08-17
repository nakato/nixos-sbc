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


## Supported Single Board Computer Quick Reference

For full details, see board page.  Every SBC in existance has quirks, some bigger some smaller, see the board Info pages for known quirks and issues.
Info pages are currently not standarised and may not be complete.

| Board Manufacturer | Model           | Bootable | Kernel      | Have SBC | Board page |
| ------------------ | --------------- | -------- | ----------- | -------- | ---------- |
| BananaPi           | BPiR3           | Yes      | Upstream¹˒² | Yes      | [Info](/modules/boards/bananapi/bpir3/info.md) |
| BananaPi           | BPiR4           | Yes      | Vendor      | No       | [Info](/modules/boards/bananapi/bpir4/info.md) |
| Pine64             | Rock64v2        | Yes      | Upstream    | Yes      | [Info](/modules/boards/pine64/rock64/info.md) |
| Pine64             | Rock64v3        | Yes      | Upstream    | Yes      | [Info](/modules/boards/pine64/rock64/info.md) |
| RaspberryPi        | RPi4            | Yes      | Upstream    | Yes      | [Info](/modules/boards/raspberrypi/rpi4/info.md) |
| Xunlong            | OrangePi 5      | Untested | Upstream    | No       | [Info](/modules/boards/xunlong/opi5/info.md) |
| Xunlong            | OrangePi 5B     | Yes      | Upstream³   | Yes      | [Info](/modules/boards/xunlong/opi5/info.md) |

* ¹ Requires custom build
* ² Has minor patching
* ³ DTB is out-of-tree

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
