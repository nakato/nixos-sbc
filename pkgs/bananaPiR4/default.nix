{
  armTrustedFirmwareTools,
  buildArmTrustedFirmware,
  buildSBCUBoot,
  dtc,
  fetchFromGitHub,
  ncurses,
  pkg-config,
  ubootTools,
  linuxKernel,
  linux_6_12,
  lib,
  ...
}: rec {
  ubootBananaPiR4 =
    buildSBCUBoot {
      defconfig = "mt7988_sd_rfb_defconfig";
      extraMeta.platforms = ["aarch64-linux"];
      extraNativeBuildInputs = [pkg-config ncurses armTrustedFirmwareTools];
      extraPatches = [
        ./mt7988-persistent-mac-from-cpu-uid.patch
      ];
      postPatch = ''
        cp ${./mt7988-nixos.env} board/mediatek/mt7988/mt7988-nixos.env
        # Should include via CONFIG_DEVICE_TREE_INCLUDES, but regression in
        # makefile is causing issues.
        # Regression caused by a958988b62eb9ad33c0f41b4482cfbba4aa71564.
        #
        # For now, work around issue by copying dtsi into tree and referencing
        # it in extraConfig using the relative path.
        cp ${./mt7988-mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
      '';
      extraConfig = ''
        CONFIG_ENV_SOURCE_FILE="mt7988-nixos"
        # Unessessary as it's not actually used anywhere, value copied verbatum into env
        CONFIG_DEFAULT_FDT_FILE="mediatek/mt7988a-bananapi-bpi-r4.dtb"
        # Big kernels
        CONFIG_SYS_BOOTM_LEN=0x6000000
        # The following are used in the tooling to fixup MAC addresses
        CONFIG_BOARD_LATE_INIT=y
        CONFIG_SHA1=y
      '';
      postBuild = ''
        fiptool create --soc-fw ${armTrustedFirmwareMT7988}/bl31.bin --nt-fw u-boot.bin fip.bin
        cp ${armTrustedFirmwareMT7988}/bl2.img bl2.img
      '';
      # FIXME: Should bl2 bundle here?
      filesToInstall = ["bl2.img" "fip.bin"];
    };

  armTrustedFirmwareMT7988 =
    (buildArmTrustedFirmware rec {
      extraMakeFlags = ["USE_MKIMAGE=1" "DRAM_USE_COMB=1" "BOOT_DEVICE=sdmmc" "bl2" "bl31"];
      platform = "mt7988";
      extraMeta.platforms = ["aarch64-linux"];
      filesToInstall = ["build/${platform}/release/bl2.img" "build/${platform}/release/bl31.bin"];
    })
    .overrideAttrs (oldAttrs: {
      src = fetchFromGitHub {
        owner = "mtk-openwrt";
        repo = "arm-trusted-firmware";
        # mtksoc HEAD 2024-08-02
        rev = "bacca82a8cac369470df052a9d801a0ceb9b74ca";
        hash = "sha256-n5D3styntdoKpVH+vpAfDkCciRJjCZf9ivrI9eEdyqw=";
      };
      version = "2.10.0-mtk";
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [dtc ubootTools];
    });


  linuxPackages_frankw_6_12_bananaPiR4 = linuxKernel.packagesFor (linux_6_12.override {
    autoModules = false;

    structuredExtraConfig = with lib.kernel; {
      BTRFS_FS = module;
      BTRFS_FS_POSIX_ACL = yes;

      AUTOFS_FS = module;

      # Used by system.etc.overlay.enable as part of a perl-less build.
      EROFS_FS = module;
      EROFS_FS_ZIP_LZMA = yes;
      EROFS_FS_ZIP_DEFLATE = yes;
      EROFS_FS_ZIP_ZSTD = yes;
      EROFS_FS_PCPU_KTHREAD = yes;

      # Disable extremely unlikely features to reduce build storage requirements and time.
      FB = lib.mkForce no;
      DRM = lib.mkForce no;
      SOUND = no;
      INFINIBAND = lib.mkForce no;

      NF_TABLES = yes;
      NETFILTER_NETLINK_HOOK = module;
      NETFILTER_NETLINK_ACCT = module;
      NETFILTER_NETLINK_QUEUE = module;
      NETFILTER_NETLINK_LOG = module;
      NETFILTER_NETLINK_OSF = module;
      NETFILTER_XT_CONNMARK = module;
      NETFILTER_XT_TARGET_AUDIT = module;
      NETFILTER_XT_TARGET_CLASSIFY = module;
      NETFILTER_XT_TARGET_CONNMARK = module;
      NETFILTER_XT_TARGET_CT = module;
      NETFILTER_XT_TARGET_DSCP = module;
      NETFILTER_XT_TARGET_HL = module;
      NETFILTER_XT_TARGET_HMARK = module;
      NETFILTER_XT_TARGET_IDLETIMER = module;
      NETFILTER_XT_TARGET_LED = module;
      NETFILTER_XT_TARGET_NETMAP = module;
      NETFILTER_XT_TARGET_NFLOG = module;
      NETFILTER_XT_TARGET_NFQUEUE = module;
      NETFILTER_XT_TARGET_RATEEST = module;
      NETFILTER_XT_TARGET_TEE = module;
      NETFILTER_XT_TARGET_TPROXY = module;
      NETFILTER_XT_TARGET_TCPMSS = module;
      NETFILTER_XT_TARGET_TCPOPTSTRIP = module;
      NETFILTER_XT_MATCH_BPF = module;
      NETFILTER_XT_MATCH_CGROUP = module;
      NETFILTER_XT_MATCH_CLUSTER = module;
      NETFILTER_XT_MATCH_COMMENT = module;
      NETFILTER_XT_MATCH_CONNBYTES = module;
      NETFILTER_XT_MATCH_CONNLABEL = module;
      NETFILTER_XT_MATCH_CONNLIMIT = module;
      NETFILTER_XT_MATCH_CONNMARK = module;
      NETFILTER_XT_MATCH_CPU = module;
      NETFILTER_XT_MATCH_DCCP = module;
      NETFILTER_XT_MATCH_DEVGROUP = module;
      NETFILTER_XT_MATCH_DSCP = module;
      NETFILTER_XT_MATCH_ECN = module;
      NETFILTER_XT_MATCH_ESP = module;
      NETFILTER_XT_MATCH_HASHLIMIT = module;
      NETFILTER_XT_MATCH_HELPER = module;
      NETFILTER_XT_MATCH_HL = module;
      NETFILTER_XT_MATCH_IPCOMP = module;
      NETFILTER_XT_MATCH_IPRANGE = module;
      NETFILTER_XT_MATCH_L2TP = module;
      NETFILTER_XT_MATCH_LENGTH = module;
      NETFILTER_XT_MATCH_LIMIT = module;
      NETFILTER_XT_MATCH_MAC = module;
      NETFILTER_XT_MARK = module;
      NETFILTER_XT_MATCH_MULTIPOR = module;
      NETFILTER_XT_MATCH_NFACCT = module;
      NETFILTER_XT_MATCH_OSF = module;
      NETFILTER_XT_MATCH_OWNER = module;
      NETFILTER_XT_MATCH_PHYSDEV = module;
      NETFILTER_XT_MATCH_PKTTYPE = module;
      NETFILTER_XT_MATCH_QUOTA = module;
      NETFILTER_XT_MATCH_RATEEST = module;
      NETFILTER_XT_MATCH_REALM = module;
      NETFILTER_XT_MATCH_RECENT = module;
      NETFILTER_XT_MATCH_SCTP = module;
      NETFILTER_XT_MATCH_SOCKET = module;
      NETFILTER_XT_MATCH_STATE = module;
      NETFILTER_XT_MATCH_STATISTIC = module;
      NETFILTER_XT_MATCH_STRING = module;
      NETFILTER_XT_MATCH_TCPMSS = module;
      NETFILTER_XT_MATCH_TIME = module;
      NETFILTER_XT_MATCH_U32 = module;
      NF_CONNTRACK_MARK = yes;
      NF_CONNTRACK_LABELS = yes;
      NF_CONNTRACK_AMANDA = module;
      NF_CONNTRACK_FTP = module;
      NF_CONNTRACK_H323 = module;
      NF_CONNTRACK_IRC = module;
      NF_CONNTRACK_NETBIOS_NS = module;
      NF_CONNTRACK_SNMP = module;
      NF_CONNTRACK_PPTP = module;
      NF_CONNTRACK_SANE = module;
      NF_CONNTRACK_SIP = module;
      NF_CONNTRACK_TFTP = module;
      NF_CT_NETLINK = module;
      NF_CT_NETLINK_TIMEOUT = module;
      NFT_NUMGEN = module;
      NFT_CT = module;
      NFT_CONNLIMIT = module;
      NFT_FIB_IPV4 = module;
      NFT_FIB_IPV6 = module;
      NFT_FIB_INET = module;
      NFT_FIB_NETDEV = module;
      NFT_FLOW_OFFLOAD = module;
      NFT_LOG = module;
      NFT_LIMIT = module;
      NFT_MASQ = module;
      NFT_REDIR = module;
      NFT_NAT = module;
      NFT_TUNNEL = module;
      NFT_QUEUE = module;
      NFT_QUOTA = module;
      NFT_REJECT = module;
      NFT_COMPAT = module;
      NFT_HASH = module;
      NFT_SOCKET = module;
      NFT_OSF = module;
      NFT_TPROXY = module;
      NFT_SYNPROXY = module;
      NF_DUP_NETDEV = module;
      NFT_DUP_NETDEV = module;
      NFT_FWD_NETDEV = module;
      NF_FLOW_TABLE = module;
      NF_FLOW_TABLE_INET = module;

      IP_SET = module;
      IP_SET_BITMAP_IP = module;
      IP_SET_BITMAP_IPMAC = module;
      IP_SET_BITMAP_PORT = module;
      IP_SET_HASH_IP = module;
      IP_SET_HASH_IPMARK = module;
      IP_SET_HASH_IPPORT = module;
      IP_SET_HASH_IPPORTIP = module;
      IP_SET_HASH_IPPORTNET = module;
      IP_SET_HASH_IPMAC = module;
      IP_SET_HASH_MAC = module;
      IP_SET_HASH_NETPORTNET = module;
      IP_SET_HASH_NET = module;
      IP_SET_HASH_NETNET = module;
      IP_SET_HASH_NETPORT = module;
      IP_SET_HASH_NETIFACE = module;
      IP_SET_LIST_SET = module;
      NFT_DUP_IPV4 = module;
      IP_NF_MATCH_AH = module;
      IP_NF_MATCH_RPFILTER = module;
      IP_NF_TARGET_SYNPROXY = module;
      IP_NF_TARGET_ECN = module;
      IP_NF_RAW = module;
      IP_NF_SECURITY = module;
      IP_NF_ARP_MANGLE = module;
      NFT_DUP_IPV6 = module;
      IP6_NF_MATCH_AH = module;
      IP6_NF_MATCH_EUI64 = module;
      IP6_NF_MATCH_FRAG = module;
      IP6_NF_MATCH_OPTS = module;
      IP6_NF_MATCH_IPV6HEADER = module;
      IP6_NF_MATCH_MH = module;
      IP6_NF_MATCH_RPFILTER = module;
      IP6_NF_MATCH_RT = module;
      IP6_NF_MATCH_SRH = module;
      IP6_NF_TARGET_SYNPROXY = module;
      IP6_NF_RAW = module;
      IP6_NF_SECURITY = module;
      IP6_NF_TARGET_NPT = module;
      NF_CONNTRACK_BRIDGE = module;

      XFRM_USER = module;
      NFT_XFRM = module;
    };

    argsOverride = {
      src = fetchFromGitHub {
        owner = "frank-w";
        repo = "BPI-Router-Linux";
        # 6.12-main HEAD 2025-01-08
        rev = "3cd0a377f30740f504919d1c51d76f23e0024427";
        hash = "sha256-t8aqHi1uT2JteEqX/CAyQSVm2Uj/OqD/DMFzwNxI83o=";
      };
      version = "6.12.8-bpi-r4";
      modDirVersion = "6.12.8-bpi-r4";
    };

    defconfig = "mt7988a_bpi-r4_defconfig";

    extraMeta.vendorKernel = true;
  });

  linuxPackages_frankw_latest_bananaPiR4 = linuxPackages_frankw_6_12_bananaPiR4;
}
