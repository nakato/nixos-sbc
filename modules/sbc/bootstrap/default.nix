{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.sbc.bootstrap;
in {
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
      type = types.enum ["btrfs-subvol" "btrfs" "ext4"];
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

  config = mkMerge [
    (mkIf (config.sbc.version == "0.1") {
      sbc.bootstrap.rootFilesystem = lib.mkOptionDefault "ext4";
    })
    (mkIf (versionAtLeast config.sbc.version "0.2") {
      sbc.bootstrap.rootFilesystem = lib.mkOptionDefault "btrfs-subvol";
    })
    (mkIf (config.sbc.enable && cfg.enable) {
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

        rootfsBtrfsImage = pkgs.callPackage ./make-btrfs-fs.nix {
          storePaths = config.system.build.toplevel;
          compressImage = false;
          volumeLabel = "root";
          uuid = "18db6211-ac36-42c1-a22f-5e15e1486e0d";
          btrfs-progs = pkgs.btrfs-progs.overrideAttrs (oldAttrs: {
            patches = [
              ./mkfs-btrfs-force-root-ownership-and-time.patch
            ];
            postPatch = "";

          });
          populateImageCommands = ''
            mkdir ./files/boot
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
          '';
          # FIXME: Using subvols without / should assert (also will fail to build)
          # FIXME: Nested subvols needs to assert or gain ordering logic.
          subvolMap = let
            # UUID is for BTRFS root device, not just subvol ones.  Ooops.
            btrfsSubVolDevice = "/dev/disk/by-uuid/18db6211-ac36-42c1-a22f-5e15e1486e0d";
            fileSystems = builtins.filter (fs: ((fs.device == btrfsSubVolDevice) && (builtins.any (opt: lib.hasPrefix "subvol=" opt) fs.options))) config.system.build.fileSystems;
            stripSubVolOption = opt: lib.removePrefix "subvol=" opt;
            getSubVolOption = opts: stripSubVolOption (builtins.head (builtins.filter (opt: lib.hasPrefix "subvol=" opt) opts));
            subvolMap = builtins.listToAttrs (builtins.map (fs: {
                name = "${fs.mountPoint}";
                value = "${getSubVolOption fs.options}";
              })
              fileSystems);
          in
            subvolMap;
        };
      in
        if (builtins.elem cfg.rootFilesystem ["btrfs" "btrfs-subvol"])
        then rootfsBtrfsImage
        else rootfsExt4Image;

      boot.postBootCommands = let
        btrfsResizeCommands = ''
          ${pkgs.btrfs-progs}/bin/btrfs filesystem resize max $rootPath
        '';
        ext4ResizeCommands = ''
          ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
        '';
        resizeCommands =
          if (builtins.elem cfg.rootFilesystem ["btrfs" "btrfs-subvol"])
          then btrfsResizeCommands
          else ext4ResizeCommands;
        registrationPath =
          if (builtins.elem cfg.rootFilesystem ["btrfs" "btrfs-subvol"])
          then "/nix/nix-path-registration"
          else "/nix-path-registration";
      in ''
        # On the first boot do some maintenance tasks
        if [ -f ${registrationPath} ]; then
          set -euo pipefail
          set -x
          # Figure out device names for the boot device and root filesystem.
          rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
          rootPath=/
          if [ $rootPart = "none" ]; then
            # If rootPart is none, then /nix is the source of our fs.
            # This is for impermanence btrfs-subvol builds.
            rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /nix)
            rootPath=/nix
          fi
          # Remove BTRFS SubVol from rootPart if it exists
          rootPart=''${rootPart//\[*/}
          rootDevice=$(lsblk -npo PKNAME $rootPart)
          partNum=$(lsblk -npo PARTN $rootPart)

          # Resize the root partition and the filesystem to fit the disk
          echo ",+," | sfdisk -N$partNum --no-reread $rootDevice
          ${pkgs.parted}/bin/partprobe
          ${resizeCommands}

          # Register the contents of the initial Nix store
          ${config.nix.package.out}/bin/nix-store --load-db < ${registrationPath}

          # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
          touch /etc/NIXOS
          ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

          # Prevents this from running on later boots.
          rm -f ${registrationPath}
        fi
      '';
    })
  ];
}
