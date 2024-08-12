# SinoVoip BananaPi R4

## Status

The current level of support is probably best described as preliminary, and there are issues.

The project maintainer currently does not have access to the hardware.


## Issues

### Clocks

Kernel param `clk_ignore_unused=1` is set as if linux shuts down unknown clocks the device stops functioning.  This means the hardware is in a state where linux doesn't know about clocks it needs to manage to keep the system stable.


### RTC

No kernel support


### Module loads at boot

As referenced in the pull that added support:  
Often the mtk_soc module will fail to load during boot. A simple sudo rmmod mtk_eth / sudo modprobe mtk_eth will fix this.


### FS Resizing

As referenced in the pull that added support:  
> Sometimes the SD card wont resize itself. I tried the script from this repository and the original script from nixpkgs, I had intermittent issues regardless of the script. I don't think this is a code issue with the boot script.


### MAC Addresses

It is currently unknown where MAC addresses are coming from, I'm guessing ethernet is using random MACs.  WiFi is currently uninvestigated.
