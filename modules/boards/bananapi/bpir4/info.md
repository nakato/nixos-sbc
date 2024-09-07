# SinoVoip BananaPi R4

## Status

The devices is currently very new, both in this repository and in general.  In this repository support is best described as preliminary.

The issues that are listed describe the state with a non-upstream 6.10 kernel.


The project maintainer currently does not have access to the hardware.


## Issues

### Clocks

Kernel param `clk_ignore_unused=1` is set as if linux shuts down unknown clocks the device stops functioning.  This means the hardware is in a state where linux doesn't know about clocks it needs to manage to keep the system stable.


### PCIe

PCIe root does not appear, meaning PCIe is not functional at this time.


### Module loads at boot

As referenced in the pull that added support:

> Often the mtk_soc module will fail to load during boot. A simple sudo rmmod mtk_eth / sudo modprobe mtk_eth will fix this.


### FS Resizing

As referenced in the pull that added support:

> Sometimes the SD card wont resize itself. I tried the script from this repository and the original script from nixpkgs, I had intermittent issues regardless of the script. I don't think this is a code issue with the boot script.


### MAC Addresses

Ethernet MAC are set as Locally Administered and are generated from a device-unique CPU ID.

WiFi has not been looked into due to lack of hardware.  If you have hardwardware with wifi, get in touch.
