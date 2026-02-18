{ config, lib, pkgs, ... }:

{

  boot.loader.grub.timeoutStyle = "hidden";

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "gmk";
  systemd.network.wait-online.enable = false;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "can" "can_raw" "vcan" "can_dev"];
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
    can-utils
    pkgs.rocmPackages.rocm-smi
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.amdgpu.opencl.enable = true;

  systemd.network.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  systemd.network.networks."80-can" = {
    matchConfig.Name = "can0";
    networkConfig = { };
    extraConfig = ''
      [Link]
      RequiredForOnline=no

      [CAN]
      BitRate=500000
      RestartSec=100ms
    '';
  };

  # systemd.services.can-bridge = {
  #   path = with pkgs; [ usbutils ];

  #   description = "CAN Bridge Setup for ROS Core";

  #   # Unit section equivalents
  #   after = [ "docker.service" ];
  #   requires = [ "docker.service" ];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.bash}/bin/bash /home/raptors/raptor_ws/.devcontainer/services/can-bridge-setup.sh";
  #     ExecStartPost = "${pkgs.coreutils}/bin/rm -f /home/raptors/raptor_ws/.can_bridge_rex_waiting";
  #   };
  # };

  # systemd.paths.can-bridge = {
  #   description = "Watch for CAN bridge trigger file";

  #   wantedBy = [ "multi-user.target" ];

  #   pathConfig = {
  #     PathExists = "/home/raptors/raptor_ws/.can_bridge_rex_waiting";
  #     MakeDirectory = false;
  #     Unit = "can-bridge.service";
  #   };
  # };

}