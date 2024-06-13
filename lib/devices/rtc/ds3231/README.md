# DS3231

The DS3231 is a cheap and widely available i2c RTC module available in
various form-factors.  It uses i2c address 0x68.

My favorite variant is one that fits on the Pi2+ header and includes a
soldered-on rechargeable battery.


## Requirements

i2c bus with address 0x68 free.

## Usage

You need to know the name of the i2c bus as described in the devices
device-tree.  You can consult your devices device tree or poke around
`/sys/firmware/devicetree/base/aliases/`.

The i2c bus must be enabled, `status = "okay"`, this will currently be forced
due to how the DT simple-overlay is structured, but is not intentional, expect
it to change and enable your i2c bus if it is not already enabled.
The board contributor should have defined user-exposed i2c interfaces at
sbc.board.i2c.devices.\*.

Finally, enable the dtOverlay with:
```nix
host = nixosSystem {
  modules = [
    # Note: The deviceBuilder API should be considered unstable.
    (nixos-sbc.deviceBuilder.rtc.ds3231 ({config}: {i2cConfig = config.sbc.board.i2c.devices.i2c0;}))
  ];
}
```
