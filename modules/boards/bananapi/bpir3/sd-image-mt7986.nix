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
      uboot,
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
        buildInputs = [uboot];

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

          # Last 100s is being lazy about GPT backup, which should be 36s is size.
          imageSize=$((rootPartEnd + 100))
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

          if [ ${builtins.toString compress} = 1 ]; then
            zstd --rm -T0 -19 $img
          fi
        '';
      }
  ) {uboot = sbcPkgs.ubootBananaPiR3;};
}
