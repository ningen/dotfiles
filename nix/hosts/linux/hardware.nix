# Placeholder for the target machine.
#
# Replace this file with the `hardware-configuration.nix` produced by
# `nixos-generate-config` after the first boot (or from the live ISO), e.g.
#
#   sudo nixos-generate-config --show-hardware-config > nix/hosts/linux/hardware.nix
#
# The values below only exist so the flake evaluates before the real hardware
# is known. Labels must match the filesystems created by the installer.
{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];
}
