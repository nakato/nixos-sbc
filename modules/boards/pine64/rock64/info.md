# Pine64 Rock64

## Status

* v2: Works with reduced peformance
* v3: Works


## Quirks

### RTC

v2 does not have an easy way to attach a battery for the RTC.
v3 does not come with a battery for the RTC but one may be easily connected.

The RTC is disabled on both models by default via a module blacklist.

It can be re-enabled if a battery has been attached with `rtc.devices.rk808.enable = true`.


### Serial

As with all RockChip devices, serial baud is 1500000, which does not work with all serial adapters.


## Issues

### Rock64v2 memory corruption and speed

Rock64v2 hardware has issues with memory trace routing causing instability (memory corruption).
To deal with this a u-boot with a substantually lower memory speed is used, impacting performance.

Rock64v3 is not subject to this issue.
