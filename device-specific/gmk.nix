{ config, lib, pkgs, ... }:

{
  imports = [ ../additional-features/docker-wait-for-network.nix ];

  boot.loader.grub.timeoutStyle = "hidden";

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "gmk";
  systemd.network.wait-online.enable = false;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-amd" "amdgpu" ];
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

  swapDevices = [ 
    { device = "/dev/disk/by-uuid/92e72a49-f6ab-4b77-aa20-49e4d6d5e5b7"; }
  ];

  hardware.graphics.enable = true;

  hardware.enableRedistributableFirmware = true;

  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    rocmPackages.rocm-smi
    rocmPackages.rocminfo
    # rocm-runtime
  ];

  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
    rocmPackages.rocminfo
    cowsay
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.amdgpu.opencl.enable = true;

  systemd.network.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  # OAK cam udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"
  '';

  programs.bash = {
    shellAliases = {
      rex-debug = "( cd ~/rex-debug ; ./run.sh )";
    };
  };

}
