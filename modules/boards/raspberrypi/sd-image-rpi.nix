{
  config,
  pkgs,
  sbcPkgs,
  ...
}: {
  system.build.sdImage = pkgs.callPackage (
    {
      stdenv,
      e2fsprogs,
      gptfdisk,
      util-linux,
      zstd,
    }: let
      name = "nixos-sd-${config.sbc.board.vendor}-${config.sbc.board.model}";
      compress = true;
      imageName = "${name}-v${config.sbc.version}.raw";
    in
      stdenv.mkDerivation {
        inherit name;
        nativeBuildInputs = [
          e2fsprogs
          gptfdisk
          util-linux
          zstd
        ];
        buildInputs = [];

        buildCommand = ''
          root_fs=${config.system.build.rootfsImage}

          mkdir -p $out/nix-support $out/sd-image
          export img=$out/sd-image/${imageName}

          echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
          echo "file sd-image $img${
            if compress
            then ".zst"
            else ""
          }" >> $out/nix-support/hydra-build-products

          ## Sector Math
          # Firmware static 32MB
          rpiFwStart=8192
          rpiFwEnd=69631

          # End staticly sized partitions

          rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
          rootPartStart=$((rpiFwEnd + 1))
          rootPartEnd=$((rootPartStart + rootSizeBlocks - 1))

          # Last 100s is being lazy about GPT backup, which should be 36s is size.
          imageSize=$((rootPartEnd + 100))
          imageSizeB=$((imageSize * 512))

          truncate -s $imageSizeB $img

          # Create a new GPT data structure
          sgdisk -o \
          --set-alignment=2 \
          -n 1:$rpiFwStart:$rpiFwEnd -c 1:firmware -t 1:0700 \
          -n 2:$rootPartStart:$rootPartEnd -c 2:root -A 2:set:2 \
          $img

          # Copy firmware
          dd conv=notrunc if=${sbcPkgs.raspberryPiFirmware} of=$img seek=$rpiFwStart

          # Copy root filesystem
          dd conv=notrunc if=$root_fs of=$img seek=$rootPartStart

          if [ ${builtins.toString compress} = 1 ]; then
            zstd --rm -T0 -19 $img
          fi
        '';
      }
  ) {};
}
