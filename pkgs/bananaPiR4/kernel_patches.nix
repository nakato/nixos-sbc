{fetchpatch}: [
  {
    name = "build.sh: add build script,config,defconfig and fit source";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/2a4d02669e6615d55aff08e3794ed6b0bf384907.patch";
      hash = "sha256-gXHrduSE8qQVOjIBc7JHl+3mqp3sm4Ld6kCyowkv+P8=";
    };
  }
  {
    name = "defconfig: r4: add sram driver";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/a6a88b8bc56bad2156e6ae884fa3467a11b77189.patch";
      hash = "sha256-TS1E7ZHZstkAW1SI6rlBvUqim6BVwblah50Dug7V6co=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988: add basic ethernet-nodes";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/6ecbb2065dc053b2124aba3e6f37447c567ece6e.patch";
      hash = "sha256-yhsYowECScOG3mQUEvezQTBYFrw3QcLVgVasM2ChnxQ=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988: add switch node";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/b751190d1161d9d17360684f471fb82be3ee53c3.patch";
      hash = "sha256-maB5y1qXdZV80TbRLJQd1rJvspoEqqvavlnkOb+loJ0=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988a-bpi-r4: add aliases for ethernet";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/3f5a5bf4161d16bcc231000fd30ec782814a3433.patch";
      hash = "sha256-1BFTmKQFBvXBhr1S97DI/DTbyaHeYnIw2CWWxGnevvo=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988a-bpi-r4: add sfp cages and link to gmac";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/49efdb79e35ddc7fecd06655ba5ac42d1c0eddba.patch";
      hash = "sha256-FWerMF2Nzb5TULu6quJck1WJAb87wQE1U4rORjZJkJY=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988a-bpi-r4: configure switch phys and leds";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/f4312adbbc5176411dbb34618f941f7be3684aab.patch";
      hash = "sha256-x72hUANG5q7bwuteRUM034pIxX31j1qseCVwLk8BBjA=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988a-bpi-r4: drop readonly from bl2 partition";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/3d1b8e94cffd72de36c26e84d9e8c3109192fa54.patch";
      hash = "sha256-8r6PkA3/MnZcSjdDa/7XXvFLJmryTDjQTheYizs9TWE=";
    };
  }
  {
    name = "dt-bindings: net: pcs: mediatek,sgmiisys: add phys and resets";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/3e796fb6bf6a5a7bb89e22ceb470d1e3d01997f0.patch";
      hash = "sha256-i4T1OM7Fm29oJR4MtGNJy8ElQ8zNZXJ+lpIlHvRKNPQ=";
    };
  }
  {
    name = "dt-binding: sgmiisys: re-add pcs-cells";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/2631a96bdde6b172d4d6bb92749d755a90907106.patch";
      hash = "sha256-rAiIPSv9sO6yD73kAkFwebtxtmXyMZ/qC08ey6xKB2A=";
    };
  }
  {
    name = "dts: re-add sgmiisys";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/3c4b1067a2b790f3b10d56868f4397607db8f57e.patch";
      hash = "sha256-3OqSHwi4ykcapgl7yLN+YWYvsQvu0mFmzlrfQsXHOAI=";
    };
  }
  {
    name = "arm64: dts: mt7988: add cpufreq calibration efuse subnode";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/444774c34ea084ba8faf0392b06550e7efd75c83.patch";
      hash = "sha256-hq1dWw/Aem+rcvT1Yil441AKqlwBj2qAHl/3s4XG3XY=";
    };
  }
  {
    name = "net: ethernet: mtk_eth_soc: move desc assignment below check for its txd3";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/0b6522208465cade1a99b967f31548466ab02e99.patch";
      hash = "sha256-xg1EV/OAfvBw9s7QLamDDneKLh9WekHpN+nszw0pb2E=";
    };
  }
  {
    name = "WIP: dts64: r4: add ubi partition to spin nand";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/760cab92fa18a392a631dd017546dffe42f3db35.patch";
      hash = "sha256-Gb6zTSlOGDiwD/anEXAm5+/J5AWCZnZ7Pi/kyKGb4sw=";
    };
  }
  {
    name = "add mtd-rw driver";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/80ff3a1bc8e4225b3722896562eb8270d409d86f.patch";
      hash = "sha256-48Y2EE0w3c1qHaGz1hcaPPwWI1Ugc0R1nQnv7UCkByE=";
    };
  }
  {
    name = "arm64: dts: add usxgmii pcs and link both pcs";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/0e49f2b38bd8ea3fc6e2264d414c97adabd6d0d7.patch";
      hash = "sha256-4nxbMx1YE9meL054mNyh+0hwl7xaeVH2jnfvRco7iew=";
    };
  }
  {
    name = "arm64: dts: update bpi-r4.dtsi to actual state";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/389ad7f770369e28b9b23a9d86eb322720f474c8.patch";
      hash = "sha256-Ki73Yu5S5MNp02tc0hA7ZIAvyXy0NFmCn0wxGmhIHAM=";
    };
  }
  {
    name = "net: ethernet: mtk_eth_soc: add paths and SerDes modes for MT7988";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/228ffb0c4cdce2c6b6b842b543acc10892f95fdc.patch";
      hash = "sha256-+bG6rbYW56DVmNgj9ubEXoT8LEPwMny8rZyfECcd3Pc=";
    };
  }
  {
    name = "net: phylink: keep and use MAC supported_interfaces in phylink struct";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/b3bfd301783926fed1f2a91410061c6bc79b6a2e.patch";
      hash = "sha256-Z7doFxT2EJT5BMh8WCsJI4eGYkfLAW0zWbOznM18H64=";
    };
  }
  {
    name = "net: phy: introduce phy_interface_copy helper";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/07a732586f88bdd6dfc3d9c65819241611df4bdc.patch";
      hash = "sha256-NNQSzTKFjCyASNif9Ry+BxQ3YM0wYjmja5/lqBeC0pM=";
    };
  }
  {
    name = "net: phylink: introduce internal phylink PCS handling";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/b248bd3dc9ddabb5542f99c594cdbed810a33c18.patch";
      hash = "sha256-IoNJd6Z9W6HTnYo3ltxdECCjZ/0/q5ldNWIzQEaq0tk=";
    };
  }
  {
    name = "net: phylink: add phylink_release_pcs() to externally release a PCS";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/5846b7ef4abf4bdb0989f6d85b915cc364368fd9.patch";
      hash = "sha256-y69L2pBKJ4/jxr42V58tKT38kU0lfc9i+FoT58unDnE=";
    };
  }
  {
    name = "net: pcs: implement Firmware node support for PCS driver";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/d527afa29f209e08cb9dd78e5918993606f30229.patch";
      hash = "sha256-DCdCHq+5PdD+YmMc4SzuBce8fuoqJIU6EUjGLr2D8BU=";
    };
  }
  {
    name = "net: phylink: support late PCS provider attach";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/4c1b33d1c4a2f12931a05c822ea531effb2e7430.patch";
      hash = "sha256-3ODZNWPqUtKbpb51tcu0toMFFSW2IkQ7V+5g+nWmAqM=";
    };
  }
  {
    name = "dt-bindings: net: ethernet-controller: permit to define multiple PCS";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/2d9916c7408ec21e596662e0ff628f4d5268d465.patch";
      hash = "sha256-KzXBtLg/XPZDz30uktEu75WS1/7uJGg5j0HornRJ2cU=";
    };
  }
  {
    name = "net: pcs: pcs-mtk-lynxi: add platform driver for MT7988";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/7662dda7ba0f231c978dd26acc5b4b5042124aa4.patch";
      hash = "sha256-HvhFdoQhxyo7ays7oaAqgWVVrdPnNGlC+X2ZpdniapQ=";
    };
  }
  {
    name = "dt-bindings: net: pcs: add bindings for MediaTek USXGMII PCS";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/637d493c66ef8cf3f09613f296efd17790744fb4.patch";
      hash = "sha256-C01Shz1rJNRontdfLi1DTdD5D9UB0GTlS9f/rC1WjEU=";
    };
  }
  {
    name = "net: pcs: add driver for MediaTek USXGMII PCS";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/d10d195fc9d60b77fbcbd7d50912a136c2809022.patch";
      hash = "sha256-w95ycaNlsWbjdcnpirOoyKLJEWRZaLG6CO6wv2Xbv9A=";
    };
  }
  {
    name = "net: ethernet: mtk_eth_soc: add more DMA monitor for MT7988";
    patch = fetchpatch {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/f1c2fa1e70c0f41617d1fea82fd9f63396908506.patch";
      hash = "sha256-11SJNmZGTuLSYp+XLjGX6xr3OGLYlwbCs+gDGpM8a7A=";
    };
  }
]
