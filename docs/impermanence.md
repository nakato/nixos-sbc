# Impermanence

## Provision directly to Impermanence

It is possible to provision the SDImage in a manner that impermanence is available from first boot.

To do so, the following snippet can be copied and edited as desired.

```nix
{config, lib, ...}: {
  fileSystems = {
    "/" = with lib; {
      device = mkForce "none";
      fsType = mkForce "tmpfs";
      options = mkForce ["size=8G" "mode=755"];
    };
    "/persistent" = {
      device = config.fileSystems."/nix".device;
      fsType = "btrfs";
      options = ["subvol=@persistent" "compress=zstd"];
      neededForBoot = true;
    };
  };
}
```


### Adding secrets after burning

After burning the image to disk, you can pre-add secrets that are defined in `environment.persistence."/persistent"` by mounting the image and making the directory under `mkdir -p /mnt/@persistent/path/to/secret/dir` and then placing the file in place.

Keep in mind, the mode on the persistent directory is copied to the target location, take special caution to ensure the permissions are not too loose or too strict.

#### Permission issue example

```nix
{
  environment.persistence."/persistent" = {
    files = [
      { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "u=rwx,g=rx,o=rx"; }; }
    ];
  };
}

```shell
(umask 0077; mkdir -p /@persistent/etc/ssh; echo "...")
```

This results in `/@persistent/etc` and `/@persistent/etc/ssh` existing iwth mode 0700.

When `/etc/ssh/ssh_host_ed25519_key` is setup during boot, `/etc/ssh` will not exist yet, and the tooling will make `/etc/ssh` permissions match the permissions in the persistance path, in this case 0700.  This will result in users with SSH keys defined in the flake being unable to log in as the SSH daemon, after dropping permissions, will be unable to access `/etc/ssh/authorized_keys.d` as the `Other` permissions are not at least 0001 (execute bit on Other) on `/etc/ssh`.
