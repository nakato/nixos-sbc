# SinoVoip BananaPi R3

## Status

Device works and the primary features work with an upstream kernel, that being switching and WiFi.


## Quirks

### PCIe

Without a kernel patch that modifies some PCIe timings some PCIe devices will not enumerate on cold boots.
With the kernel patch PCIe root will reliably enumerate, and a userspace script can re-attempt PCIe enumeration on boot getting devices to reliably detect.

Does not impact all PCIe devices, cheaper NVMe drives seem particularly problematic.


### Switch interfaces do not appear correctly unless MTK DSA drivers built into kernel.

If the MTK DSA and related drivers are built as modules, the switch hardware will appear as a single interface and not function.

This was last checked with Kernel 6.4.


### Reset/WPS buttons

The reset button pin is also used in the PCIe port, both cannot be used.

A DeviceTree Overlay is used to disable the reset button and remap the WPS button as reset.

Do not press the reset button.


### WiFi training

WiFi training data is provided by device-tree.  The contents are undocumented.  This presents two issues.

1. It is not known what antennas were used in the creation of the training data.
  * You **MUST** take into account the gain on the antennas in use and **reduce the max power**.
2. MAC addresses are encoded into this data
  * All devices by default use the "00:0C:43:26:60:00" MAC address
  * We fix this by taking the CPU serial, hashing it, using the first hash to provide stable ethernet MAC addresses, hashing that hash and using that to provide stable MAC addresses for WLAN0 and WLAN1.


### Ethernet MAC Addresses

The device does not have MAC addresses for the ethernet interfaces.  We provide one by hashing the CPU serial in u-boot and setting the persistent macs for Linux to use.


## Issues

### SPI NOR / SPI NAND

SPI NOR/NAND either do not write or read reliably.

With NixOS their use is not really desired so no attemtps to determine why and fix it has been taken, this appears to be a software issue.
