{ ... }:

{
  services.timesyncd = {
    enable = true;
    servers = [
      "192.168.1.1"
      "time.google.com"
      "time.cloudflare.com"
    ];
  };
}
