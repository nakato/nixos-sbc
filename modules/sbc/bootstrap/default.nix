{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.sbc.bootstrap;
in
{
  imports = [
    ./initial.nix
  ];

  options.sbc.bootstrap = with lib; {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        Controls the visibility of sdImage build targets under system.build
        and the requried first-boot scripting.

        This can be left enabled for systems using images created by the
        system.build.sdImage derivation from this repository.
        It should be disabled for images made with custom boot methods.
      '';
    };

    rootFilesystem = mkOption {
      type = types.enum [ "btrfs" "ext4" ];
      default = "ext4";
      description = mdDoc ''
        Format for root filesystem.
      '';
    };

    initialBootstrapImage = mkOption {
      type = types.bool;
      default = false;
      visible = false;
      description = mdDoc ''
        This option is used to change certain defaults for producing generic
        redistributable boot images.

        For example, disabling WiFi on the BPiR3 for the redistributable image
        while leaving it enabled as a user default, which will throw an assert
        until another flag is accepted.  The assert is seen to be less suprising
        than getting a system without WiFi until they find the config option.
      '';
    };
  };

  config = let
    isBtrfs = cfg.rootFilesystem == "btrfs";
  in mkIf (config.sbc.enable && cfg.enable) {
    assertions = [
      {
        assertion = config.boot.loader.generic-extlinux-compatible.enable;
        message = ''
          SD Image creation only works with generic-extlinux-compatible bootloader.
        '';
      }
    ];

    system.build.rootfsImage = let
      rootfsExt4Image = pkgs.callPackage (pkgs.path + "/nixos/lib/make-ext4-fs.nix") {
        storePaths = config.system.build.toplevel;
        compressImage = false;
        volumeLabel = "root";
        uuid = "0b5e3376-c7e9-4284-9514-9c3b51244f19";
        populateImageCommands = ''
          mkdir ./files/boot
          ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
        '';
      };

      rootfsBtrfsImage = pkgs.callPackage (pkgs.path + "/nixos/lib/make-btrfs-fs.nix") {
        storePaths = config.system.build.toplevel;
        compressImage = false;
        volumeLabel = "root";
        uuid = "18db6211-ac36-42c1-a22f-5e15e1486e0d";
        populateImageCommands = ''
          mkdir ./files/boot
          ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
        '';
      };
    in if cfg.rootFilesystem == "btrfs" then rootfsBtrfsImage else rootfsExt4Image;

    boot.postBootCommands =
    let
      btrfsResizeCommands = ''
        ${pkgs.btrfs-progs}/bin/btrfs filesystem resize max /
      '';
      ext4ResizeCommands = ''
        ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
      '';
      resizeCommands = if cfg.rootFilesystem == "btrfs" then btrfsResizeCommands else ext4ResizeCommands;
    in
    ''
      # On the first boot do some maintenance tasks
      if [ -f /nix-path-registration ]; then
        set -euo pipefail
        set -x
        # Figure out device names for the boot device and root filesystem.
        rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
        rootDevice=$(lsblk -npo PKNAME $rootPart)
        partNum=$(lsblk -npo MAJ:MIN $rootPart | ${pkgs.gawk}/bin/awk -F: '{print $2}')

        # Resize the root partition and the filesystem to fit the disk
        echo ",+," | sfdisk -N$partNum --no-reread $rootDevice
        ${pkgs.parted}/bin/partprobe
        ${resizeCommands}

        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f /nix-path-registration
      fi
    '';
  };
}
