{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.grub.timeoutStyle = "hidden";

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "rex-vm";
  networking.firewall.enable = false;
  systemd.network.wait-online.enable = false;

  boot.initrd.kernelModules = [ "can" "can_raw" "vcan" "can_dev"];
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.extraModulePackages = [ ];
  boot.kernelModules = [ "kvm-intel" ];

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libglvnd
    icu
  ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/d38679a5-baf0-4368-980f-d9834f9bcdcf";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/7888-2784";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  hardware.graphics.enable = true;

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    can-utils
    cowsay
  ];

  systemd.network.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  systemd.network.netdevs."10-can0" = {
    netdevConfig = {
        Name = "can0";
        Kind = "vcan";
    };
  };

  systemd.network.networks."10-can0" = {
    matchConfig.Name = "can0";
  };

  # OAK cam udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"
  '';
}