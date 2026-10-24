{ config, lib, pkgs, ... }:

{
  imports = [ ../additional-features/docker-wait-for-network.nix ];

  boot.loader.grub.timeoutStyle = "hidden";

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nuc";
  systemd.network.wait-online.enable = false;

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libglvnd
    icu
  ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/7133a168-dc13-42ad-a2de-b114c2017fd5";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/A162-D65E";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/ac7d7fde-7226-425c-99c8-c5356b01bf16"; }
    ];

  hardware.graphics.enable = true;

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    cowsay
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  systemd.network.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  programs.bash = {
    shellAliases = {
      rex-debug = "( cd ~/rex-debug ; ./run.sh )";
    };
  };

  # OAK cam udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"
  '';

}
