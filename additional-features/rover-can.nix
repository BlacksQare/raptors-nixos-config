
{ pkgs, ... }:

{
  boot.initrd.kernelModules = [ "can" "can_raw" "vcan" "can_dev"];
  
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

  environment.systemPackages = with pkgs; [
    can-utils
  ];
}
