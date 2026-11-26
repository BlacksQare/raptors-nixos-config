{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader.grub.timeoutStyle = "hidden";

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "rex-vm";
  systemd.network.wait-online.enable = false;

  boot.initrd.kernelModules = [ "can" "can_raw" "vcan" "can_dev"];
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.extraModulePackages = [ ];

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libglvnd
    icu
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  boot.kernelParams = ["console=ttyS0"];

  # Disable EFI - otherwise will not build
  boot.loader.grub = {
    enable = true;
    efiSupport = lib.mkForce false;
    device = lib.mkForce "/dev/vda";
    useOSProber = true; 
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  system.build.qcow2 = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = 16384;
    format = "qcow2";
    partitionTableType = "legacy";
  };

  swapDevices = [ ];

  hardware.graphics.enable = true;

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = with pkgs; [
    can-utils
    cowsay
  ];

  environment.sessionVariables = {
    QEMU_OPTS = "-nographic";
  };

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

  users.mutableUsers = false;

  users.users.root.password = "vm";
  users.users.raptors.password = "vm";
}