{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ./nvidia.nix ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "ntfs" "ntfs3" ];

  boot.loader.grub.default = 2;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/00285cbb-e83d-43f3-ae60-ebdb6873cb15";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C0D2-EF5E";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  hardware.bluetooth.enable = true;
  hardware.xpadneo.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
