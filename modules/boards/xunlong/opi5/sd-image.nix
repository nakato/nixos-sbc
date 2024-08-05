{
  config,
  pkgs,
  ...
}:
{
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

        # Partition notes
        # GPT        = LBA 1-33
        # RK Stage 1 = LBA 64
        # RK Stage 2 = LBA 16384
        # User Start = LBA 32768
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
          rkStage1Start=64
          rkStage1End=7167
          # vnvm follows stage1 (IDB)
          # vnvm contains MAC addresses and other vendor data
          # vnvmStart=7168
          rkStage2Start=16384
          rkStage2End=32767

          # End staticly sized partitions

          rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
          rootPartStart=$((rkStage2End + 1))
          rootPartEnd=$((rootPartStart + rootSizeBlocks - 1))

          # Last 100s is being lazy about GPT backup, which should be 36s is size.
          imageSize=$((rootPartEnd + 100))
          imageSizeB=$((imageSize * 512))

          truncate -s $imageSizeB $img

          # Create a new GPT data structure
          sgdisk -o \
          --set-alignment=2 \
          -n 1:$rkStage1Start:$rkStage1End -c 1:ubootTPL \
          -n 2:$rkStage2Start:$rkStage2End -c 2:ubootSPL \
          -n 3:$rootPartStart:$rootPartEnd -c 3:root -A 3:set:2 \
          $img

          # Copy firmware
          dd conv=notrunc if=${uboot}/idbloader.img of=$img seek=$rkStage1Start
          dd conv=notrunc if=${uboot}/u-boot.itb of=$img seek=$rkStage2Start

          # Copy root filesystem
          dd conv=notrunc if=$root_fs of=$img seek=$rootPartStart

          if [ ${builtins.toString compress} = 1 ]; then
            zstd --rm -T0 -19 $img
          fi
        '';
      }
  ) {uboot = config.sbc.board.xunlong.opi5.ubootPackage;};
}
