{ config, lib, pkgs, modulesPath, ... }:

{
  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia = {
    open = false;

    # Required for Wayland
    modesetting.enable = true;
    
    # Recommended for power management
    powerManagement.enable = true;
    
    # Ensure you are using a stable driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = with pkgs; [ 
    cudatoolkit
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
}