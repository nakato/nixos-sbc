{
  armTrustedFirmwareTools,
  buildArmTrustedFirmware,
  buildSBCUBoot,
  dtc,
  fetchFromGitHub,
  lib,
  linuxKernel,
  linux_6_14,
  ncurses,
  pkg-config,
  ubootTools,
  which,
  python3,
  ...
}: rec {
  ubootBananaPiR3 = buildSBCUBoot {
    defconfig = "mt7986a_bpir3_sd_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    extraNativeBuildInputs = [pkg-config ncurses armTrustedFirmwareTools];
    extraPatches = [
      ./mt7986-persistent-mac-from-cpu-uid.patch
      ./mt7986-persistent-wlan-mac-from-cpu-uid.patch
    ];
    postPatch = ''
      cp ${./mt7986-nixos.env} board/mediatek/mt7986/mt7986-nixos.env
      # Should include via CONFIG_DEVICE_TREE_INCLUDES, but regression in
      # makefile is causing issues.
      # Regression caused by a958988b62eb9ad33c0f41b4482cfbba4aa71564.
      #
      # For now, work around issue by copying dtsi into tree and referencing
      # it in extraConfig using the relative path.
      cp ${./mt7986-mmcboot.dtsi} arch/arm/dts/nixos-mmcboot.dtsi
    '';
    extraConfig = ''
      CONFIG_ENV_SOURCE_FILE="mt7986-nixos"
      # Unessessary as it's not actually used anywhere, value copied verbatum into env
      CONFIG_DEFAULT_FDT_FILE="mediatek/mt7986a-bananapi-bpi-r3.dtb"
      # Big kernels
      CONFIG_SYS_BOOTM_LEN=0x6000000
      # The following are used in the tooling to fixup MAC addresses
      CONFIG_BOARD_LATE_INIT=y
      CONFIG_SHA1=y
      CONFIG_OF_BOARD_SETUP=y
    '';
    postBuild = ''
      fiptool create --soc-fw ${armTrustedFirmwareMT7986}/bl31.bin --nt-fw u-boot.bin fip.bin
      cp ${armTrustedFirmwareMT7986}/bl2.img bl2.img
    '';
    # FIXME: Should bl2 bundle here?
    filesToInstall = ["bl2.img" "fip.bin"];
  };

  armTrustedFirmwareMT7986 =
    (buildArmTrustedFirmware rec {
      extraMakeFlags = ["USE_MKIMAGE=1" "DRAM_USE_DDR4=1" "BOOT_DEVICE=sdmmc" "bl2" "bl31"];
      platform = "mt7986";
      extraMeta.platforms = ["aarch64-linux"];
      filesToInstall = ["build/${platform}/release/bl2.img" "build/${platform}/release/bl31.bin"];
    })
    .overrideAttrs (oldAttrs: {
      src = fetchFromGitHub {
        owner = "mtk-openwrt";
        repo = "arm-trusted-firmware";
        # mtksoc HEAD 2025-03-12
        rev = "e090770684e775711a624e68e0b28112227a4c38";
        hash = "sha256-VI5OB2nWdXUjkSuUXl/0yQN+/aJp9Jkt+hy7DlL+PMg=";
      };
      version = "2.12.0-mtk";
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [dtc ubootTools which python3];
    });

  linuxPackages_6_14_bananaPiR3 = linuxKernel.packagesFor (linux_6_14.override {
    kernelPatches = [
      {
        # Cold boot PCIe/NVMe have stability issues.
        # See: https://forum.banana-pi.org/t/bpi-r3-problem-with-pcie/15152
        #
        # FrankW's first patch added a 100ms sleep, this was rejected upstream.
        # Jianjun posted a patch to the forum for testing, and it appears to me
        # to have accidentally missed a write to the registers between the two
        # sleeps.  This version is modified to include the write, and results
        # in the PCI bridge appearing reliably, but not the NVMe device.
        #
        # Without this patch, the PCI bridge is not present, and rescan does
        # not discover it.  Removing the bridge and then rescanning repeatably
        # gets the NVMe working on cold-boot.
        name = "PCI: mediatek-gen3: handle PERST after reset";
        patch = ./linux-mtk-pcie.patch;
      }
      {
        # Prevent crashing due to missing rates in wifi data
        #
        # See: https://forum.banana-pi.org/t/bpi-r3-crash-in-sta-set-sinfo-0xa18/15290
        # https://github.com/openwrt/openwrt/issues/13198
        name = "avoid-crashing-missing-band.patch";
        patch = ./780-avoid-crashing-missing-band.patch;
      }
    ];

    ignoreConfigErrors = true;
    structuredExtraConfig = with lib.kernel; {
      # Disable extremely unlikely features to reduce build storage requirements and time.
      FB = lib.mkForce no;
      DRM = lib.mkForce no;
      SOUND = no;
      INFINIBAND = lib.mkForce no;

      # PCIe
      PCIE_MEDIATEK = yes;
      PCIE_MEDIATEK_GEN3 = yes;
      # SD/eMMC
      MTD_NAND_ECC_MEDIATEK = yes;
      # Net
      BRIDGE = yes;
      HSR = yes;
      NET_DSA = yes;
      NET_DSA_TAG_MTK = yes;
      NET_DSA_MT7530 = yes;
      NET_VENDOR_MEDIATEK = yes;
      PCS_MTK_LYNXI = yes;
      NET_MEDIATEK_SOC_WED = yes;
      NET_MEDIATEK_SOC = yes;
      NET_MEDIATEK_STAR_EMAC = yes;
      MEDIATEK_GE_PHY = yes;
      # WLAN
      WLAN = yes;
      WLAN_VENDOR_MEDIATEK = yes;
      MT76_CORE = module;
      MT76_LEDS = yes;
      MT76_CONNAC_LIB = module;
      MT7915E = module;
      MT798X_WMAC = yes;
      # Pinctrl
      EINT_MTK = yes;
      PINCTRL_MTK = yes;
      PINCTRL_MT7986 = yes;
      # Thermal
      MTK_THERMAL = yes;
      MTK_SOC_THERMAL = yes;
      MTK_LVTS_THERMAL = yes;
      # Clk
      COMMON_CLK_MEDIATEK = yes;
      COMMON_CLK_MEDIATEK_FHCTL = yes;
      COMMON_CLK_MT7986 = yes;
      COMMON_CLK_MT7986_ETHSYS = yes;
      # other
      MEDIATEK_WATCHDOG = yes;
      REGULATOR_MT6380 = yes;
    };
  });

  /*
  This kernel is minimal in comparison to the "autoModules = true" default kernel.
  If it is missing something that makes it not usable to you on your device, please
  request its addition.  Even if it has been explicitly disabled below it is likely
  there won't be an issue re-enabling it.
  */
  linuxPackages_6_14_bananaPiR3_minimal = linuxKernel.packagesFor (linuxPackages_6_14_bananaPiR3.kernel.override {
    autoModules = false;

    structuredExtraConfig = with lib.kernel;
      linuxPackages_6_14_bananaPiR3.kernel.structuredExtraConfig
      // {
        ARCH_ACTIONS = no;
        ARCH_SUNXI = no;
        ARCH_ALPINE = no;
        ARCH_APPLE = no;
        ARCH_BCM = no;
        ARCH_BCM2835 = no;
        ARCH_BCM_IPROC = no;
        ARCH_BCMBCA = no;
        ARCH_BRCMSTB = no;
        ARCH_BERLIN = no;
        ARCH_EXYNOS = no;
        ARCH_SPARX5 = no;
        ARCH_K3 = no;
        ARCH_LG1K = no;
        ARCH_HISI = no;
        ARCH_KEEMBAY = no;
        ARCH_MESON = no;
        ARCH_MVEBU = no;
        ARCH_NXP = no;
        ARCH_LAYERSCAPE = no;
        ARCH_MXC = no;
        ARCH_S32 = no;
        ARCH_MA35 = no;
        ARCH_NPCM = no;
        ARCH_QCOM = no;
        ARCH_REALTEK = no;
        ARCH_RENESAS = no;
        ARCH_ROCKCHIP = no;
        ARCH_SEATTLE = no;
        ARCH_INTEL_SOCFPGA = no;
        ARCH_STM32 = no;
        ARCH_SYNQUACER = no;
        ARCH_TEGRA = no;
        ARCH_TESLA_FSD = no;
        ARCH_SPRD = no;
        ARCH_THUNDER = no;
        ARCH_THUNDER2 = no;
        ARCH_UNIPHIER = no;
        ARCH_VEXPRESS = no;
        ARCH_VISCONTI = no;
        ARCH_XGENE = no;
        ARCH_ZYNQMP = no;

        # If both ACPI and DT supported, one is picked at boot.
        # This device is DT based, no need for any ACPI stuff.
        ACPI = no;

        CAN = no;
        NFC = no;
        NET_9P = no;
        XEN = lib.mkForce no;
        XEN_DOM0 = lib.mkForce no;

        VIRT_DRIVERS = lib.mkForce no;
        STAGING_MEDIA = no;
        CHROME_PLATFORMS = lib.mkForce no;
        COMMON_CLK_RK808 = no;
        COMMON_CLK_SCMI = no;
        COMMON_CLK_SCPI = no;
        COMMON_CLK_CS2000_CP = no;
        COMMON_CLK_S2MPS11 = no;
        COMMON_CLK_XGENE = no;
        COMMON_CLK_PWM = no;
        COMMON_CLK_RS9_PCIE = no;
        COMMON_CLK_VC3 = no;
        COMMON_CLK_VC5 = no;
        COMMON_CLK_BD718XX = no;

        SOUNDWIRE = no;

        ARM_SCMI_PERF_DOMAIN = no;
        ARM_SCMI_POWER_DOMAIN = no;
        ARM_SCPI_POWER_DOMAIN = no;

        IIO = no;

        FPGA = no;

        AUTOFS_FS = module;

        # Used by system.etc.overlay.enable as part of a perl-less build.
        EROFS_FS = module;
        EROFS_FS_ZIP_LZMA = yes;
        EROFS_FS_ZIP_DEFLATE = yes;
        EROFS_FS_ZIP_ZSTD = yes;
        EROFS_FS_PCPU_KTHREAD = yes;

        ISO9660_FS = lib.mkForce no;
        UDF_FS = lib.mkForce no;

        NETWORK_FILESYSTEMS = no;

        GOOGLE_FIRMWARE = no;
        GOOGLE_CBMEM = no;
        GOOGLE_COREBOOT_TABLE = no;

        EFI_ESRT = no;
        EFI_VARS_PSTORE = no;
        EFI_PARAMS_FROM_FDT = no;
        EFI_RUNTIME_WRAPPERS = no;
        EFI_GENERIC_STUB = no;
        EFI_ARMSTUB_DTB_LOADER = no;
        EFI_CAPSULE_LOADER = no;
        EFI_EARLYCON = no;

        HID_A4TECH = no;
        HID_APPLE = no;
        HID_BELKIN = no;
        HID_CHERRY = no;
        HID_CHICONY = no;
        HID_CYPRESS = no;
        HID_EZKEY = no;
        HID_ITE = no;
        HID_KINSINGTON = no;
        HID_LOGITECH = no;
        LOGIRUMBLEPAD2_FF = lib.mkForce no;
        LOGIG940_FF = lib.mkForce no;
        HID_REDRAGON = no;
        HID_MICROSOFT = no;
        HID_MONTEREY = no;
        HID_MULTITOUCH = no;
        I2C_HID = no;

        HW_RANDOM_BCM2835 = no;
        HW_RANDOM_IPROC_RNG200 = no;
        HW_RANDOM_OMAP = no;
        HW_RANDOM_VIRTIO = no;
        HW_RANDOM_HISI = no;
        HW_RANDOM_HISTB = no;
        HW_RANDOM_XGENE = no;
        HW_RANDOM_STM32 = no;
        HW_RANDOM_MESON = no;
        HW_RANDOM_CAVIUM = no;
        HW_RANDOM_EXYNOS = no;
        HW_RANDOM_OPTEE = no;
        HW_RANDOM_NPCM = no;

        LIRC = lib.mkForce no;
        CEC_CORE = no;
        MEDIA_CEC_RC = lib.mkForce no;
        MEDIA_CEC_SUPPORT = no;
        MEDIA_SUPPORT = no;
        MEDIA_USB_SUPPORT = lib.mkForce no;
        VIDEO_MEDIATEK_JPEG = no;
        VIDEO_MEDIATEK_VCODEC_SCP = no;
        VIDEO_MEDIATEK_VCODEC = no;
        VIDEO_IMX_MIPI_CSIS = no;
        VIDEO_IMX8_ISI = no;
        VIDEO_IMX8_ISI_M2M = no;
        VIDEO_IR_I2C = no;
        VIDEO_CAMERA_SENSOR = no;

        WIREGUARD = module;
        IPVLAN = module;
        VXLAN = module;
        GENEVE = module;

        NET_VENDOR_MELLANOX = no;

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

        PPP = module;
        PPP_BSDCOMP = module;
        PPP_DEFLATE = module;
        PPP_FILTER = yes;
        PPP_MPPE = module;
        PPPOE = module;

        CRYPTO_POLYVAL_ARM64_CE = module;
        CRYPTO_DEV_SAFEXCEL = module;
        CRYPTO_USER_API_HASH = module;
        CRYPTO_USER_API_SKCIPHER = module;
        CRYPTO_USER_API_AEAD = module;

        SFP = module;
        MDIO_I2C = module;
      };
  });
  linuxPackages_latest_bananaPiR3 = linuxPackages_6_14_bananaPiR3;
}
