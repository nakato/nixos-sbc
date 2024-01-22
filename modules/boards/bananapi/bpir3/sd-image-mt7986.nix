{ config
, lib
, pkgs
, sbcPkgs
, ...
}:
with lib;
{
  system.build.rootfsExt4Image = pkgs.callPackage (pkgs.path + "/nixos/lib/make-ext4-fs.nix") {
    storePaths = config.system.build.toplevel;
    compressImage = false;
    volumeLabel = "root";
    uuid = "0b5e3376-c7e9-4284-9514-9c3b51244f19";
    populateImageCommands = ''
      mkdir ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  system.build.sdImage = pkgs.callPackage (
    { stdenv, e2fsprogs, gptfdisk, util-linux, uboot }: stdenv.mkDerivation {
      name = "nixos-bananapir3-sd";
      nativeBuildInputs = [
        e2fsprogs gptfdisk util-linux
      ];
      buildInputs = [ uboot ];
      imageName = "nixos-bananapir3-sd";
      compressImage = false;

      buildCommand = ''
        root_fs=${config.system.build.rootfsExt4Image}

        mkdir -p $out/nix-support $out/sd-image
        export img=$out/sd-image/nixos-bananapir3-sd.raw

        echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
        echo "file sd-image $img" >> $out/nix-support/hydra-build-products

        ## Sector Math
        # Can go anywhere?  Does it look for "bl2" as a name?
        bl2Start=34
        bl2End=8191

        envStart=8192
        envEnd=9215

        # Factory?
        factoryStart=9216
        factoryEnd=13311

        # It is said we can resize this and place it wherever like bl2 too.
        fipStart=13312
        fipEnd=17407

        # End staticly sized partitions

        rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
        rootPartStart=$((fipEnd + 1))
        rootPartEnd=$((rootPartStart + rootSizeBlocks - 1))

        # Image size is firmware + boot + root + 100s
        # Last 100s is being lazy about GPT backup, which should be 36s is size.

        imageSize=$((fipEnd + 1 + bootSizeBlocks + rootSizeBlocks + 100))
        imageSizeB=$((imageSize * 512))

        truncate -s $imageSizeB $img

        # Create a new GPT data structure
        sgdisk -o \
        --set-alignment=2 \
        -n 1:$bl2Start:$bl2End -c 1:bl2 -A 1:set:2:1 \
        -n 2:$envStart:$envEnd -c 2:u-boot-env \
        -n 3:$factoryStart:$factoryEnd -c 3:factory \
        -n 4:$fipStart:$fipEnd -c 4:fip \
        -n 5:$rootPartStart:$rootPartEnd -c 5:root -A 5:set:2 \
        $img

        # Copy firmware
        dd conv=notrunc if=${uboot}/bl2.img of=$img seek=$bl2Start
        dd conv=notrunc if=${uboot}/fip.bin of=$img seek=$fipStart

        # Copy root filesystem
        dd conv=notrunc if=$root_fs of=$img seek=$rootPartStart
      '';
    }
  ) { uboot = sbcPkgs.armTrustedFirmwareMT7986; };

  # Copy from nixpkgs sd-card.nix
  boot.postBootCommands = ''
    # On the first boot do some maintenance tasks
    if [ -f /nix-path-registration ]; then
      set -euo pipefail
      set -x
      # Figure out device names for the boot device and root filesystem.
      rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
      bootDevice=$(lsblk -npo PKNAME $rootPart)
      partNum=$(lsblk -npo MAJ:MIN $rootPart | ${pkgs.gawk}/bin/awk -F: '{print $2}')

      # Resize the root partition and the filesystem to fit the disk
      echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
      ${pkgs.parted}/bin/partprobe
      ${pkgs.e2fsprogs}/bin/resize2fs $rootPart

      # Register the contents of the initial Nix store
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

      # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
      touch /etc/NIXOS
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

      # Prevents this from running on later boots.
      rm -f /nix-path-registration
    fi
  '';

}
