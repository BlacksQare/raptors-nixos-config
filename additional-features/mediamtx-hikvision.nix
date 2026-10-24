{ pkgs, ... }:

{
  services.mediamtx = {
    enable = true;

    settings = {
      logLevel = "info";

      paths = {
        "HIK-MASZT1" = {
          source = "rtsp://view:Changeme@192.168.1.65:554/Streaming/Channels/101";
          sourceOnDemand = true;
        };

        "HIK-MASZT2" = {
          source = "rtsp://view:Changeme@192.168.1.66:554/Streaming/Channels/101";
          sourceOnDemand = true;
        };

        "HIK-MANIPULATOR" = {
          source = "rtsp://view:Changeme@192.168.1.67:554/Streaming/Channels/101";
          sourceOnDemand = true;
        };
      };
    };
  };
}