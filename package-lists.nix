{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    htop
    btop
    distrobox
    usbutils
    vim
    pciutils
  ];
}