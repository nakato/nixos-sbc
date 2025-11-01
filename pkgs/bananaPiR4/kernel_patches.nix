{fetchpatch2}: [
  {
    name = "build.sh: add build script,config,defconfig and fit source";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/0890d2e6cc32d7fa7494a92970e370d21b9e8d31.patch?full_index=1";
      hash = "sha256-H23zjURqfV7/goKzbGXmz/1A6Jd5+UXyvwTRCb67AJY=";
    };
  }
  {
    name = "defconfig: r4: add sram driver";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/34c94818ab43ebc59773f5035804f665b1519ee4.patch?full_index=1";
      hash = "sha256-oBAUrcARYhJJfEgHbfP/KRpaGqamqBeEtHimcR/v0IA=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988: add basic ethernet-nodes";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/57e1b74084ba42cec1177ec6baa87426c25a56ff.patch?full_index=1";
      hash = "sha256-hHpN4WICph0gec452kvM98TTT2L+8g/K6N53ByWZluk=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988: add switch node";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/1ae0def0b269c96c74abbca2d4d76ab89929237d.patch?full_index=1";
      hash = "sha256-AnND42+aO9Lhn7T53ZqfazoxzbqNfyFosn1p3t918rw=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988a-bpi-r4: add aliases for ethernet";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/94c6893d69eaac980117ef3eaf36d5bf83bb4625.patch?full_index=1";
      hash = "sha256-p8oi+V2BRFh6Rk4kt01WIvmBL1kA7kK5NqXYpMbGYDY=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988a-bpi-r4: add sfp cages and link to gmac";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/9751629b0ba547380e4db72675050c97dbecca25.patch?full_index=1";
      hash = "sha256-lHrrP/DhXJbse6KUbsCCYiDE4b0zJqNVDuc0vZddYQ8=";
    };
  }
  {
    name = "arm64: dts: mediatek: mt7988a-bpi-r4: configure switch phys and leds";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/c4f62e2309f8d3df7a700114124c6f7b75760a58.patch?full_index=1";
      hash = "sha256-ib3Z5VMtQJm5u1rWcr5bPALYfbviu1x0okuKqfq18b8=";
    };
  }
  {
    name = "dt-bindings: net: pcs: mediatek,sgmiisys: add phys and resets";
    patch = fetchpatch2 {
      url = "https://github.com/frank-w/BPI-Router-Linux/commit/7fe990d4181fa68be99aea5558c68a881b4b3289.patch?full_index=1";
      hash = "sha256-Wi1wC1XEQfAQfAqr04BC5QQ6u0b4FO+rI2ah/ogfW/w=";
    };
  }
]
