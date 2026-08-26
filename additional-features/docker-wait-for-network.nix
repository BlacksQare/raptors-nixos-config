#  Custom module that makes docker containers start after eno1 gets IP address

{ config, pkgs, ... }:

{
  systemd.services.docker = {
    after = [ "wait-for-eno1.service" ];
    requires = [ "wait-for-eno1.service" ];
  };

  systemd.services.wait-for-eno1 = {
    description = "Wait for eno1 network interface to come up";
    after = [ "network.target" ];
    script = ''
      echo "Waiting for eno1 to get an IP address..."
      for i in {1..120}; do
        # Check if the interface has an assigned IPv4 address ('inet ')
        if ${pkgs.iproute2}/bin/ip -4 addr show dev eno1 | grep -q "inet "; then
          echo "eno1 is up and has an IP!"
          exit 0
        fi
        sleep 1
      done
      
      echo "Timeout reached waiting for eno1"
      # exit 0 - docker starts anyway
      # exit 1 - docker will not start
      exit 0
    '';
    
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = 130; 
    };
  };
}