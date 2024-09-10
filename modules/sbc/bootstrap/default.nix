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
            src = pkgs.fetchFromGitHub {
              owner = "kdave";
              repo = "btrfs-progs";
              # devel 2024.09.10; Remove v6.11 release.
              rev = "c75b2f2c77c9fdace08a57fe4515b45a4616fa21";
              hash = "sha256-PgispmDnulTDeNnuEDdFO8FGWlGx/e4cP8MQMd9opFw=";
            };

            postPatch = "";

            nativeBuildInputs =
              oldAttrs.nativeBuildInputs
              ++ [
                pkgs.autoconf
                pkgs.automake
              ];
            preConfigure = "./autogen.sh";

            version = "6.11.0.pre";
          });
          populateImageCommands = ''
            mkdir ./files/boot
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
          '';
          subvolMap = {
            "/" = "@";
            "/nix" = "@nix";
            "/boot" = "@boot";
          };
        };
      in
        if (builtins.elem cfg.rootFilesystem ["btrfs" "btrfs-subvol"])
        then rootfsBtrfsImage
        else rootfsExt4Image;

      boot.postBootCommands = let
        btrfsResizeCommands = ''
          ${pkgs.btrfs-progs}/bin/btrfs filesystem resize max /
        '';
        ext4ResizeCommands = ''
          ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
        '';
        resizeCommands =
          if (builtins.elem cfg.rootFilesystem ["btrfs" "btrfs-subvol"])
          then btrfsResizeCommands
          else ext4ResizeCommands;
        registrationPath =
          if (cfg.rootFilesystem == "btrfs-subvol")
          then "/nix/nix-path-registration"
          else "/nix-path-registration";
      in ''
        # On the first boot do some maintenance tasks
        if [ -f ${registrationPath} ]; then
          set -euo pipefail
          set -x
          # Figure out device names for the boot device and root filesystem.
          rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
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
