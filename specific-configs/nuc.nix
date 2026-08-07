{ config, lib, pkgs, ... }:

{

  boot.loader.grub.timeoutStyle = "hidden";

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nuc";
  networking.firewall.enable = false;
  systemd.network.wait-online.enable = false;

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "can" "can_raw" "vcan" "can_dev"];
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
    can-utils
    cowsay
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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

  # OAK cam udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"
  '';

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