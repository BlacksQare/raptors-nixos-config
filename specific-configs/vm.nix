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
  boot.extraModulePackages = [ ];

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libglvnd
    icu
  ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/0003d2ee-d129-4f3e-8e96-ed58d98655a2";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/30BA-D067";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

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

  # OAK cam udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"
  '';
}