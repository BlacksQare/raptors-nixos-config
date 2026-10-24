
{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;

    virtualHosts."rex.teamraptors.pl" = {
      forceSSL = true;

      root = "${./nginx-wiki-html}";

      sslCertificate = "/var/lib/rex-certs/cert.pem";
      sslCertificateKey = "/var/lib/rex-certs/key.pem";
    };
  };

  # Generate the self-signed certificate locally.
  systemd.services.rex-nginx-wiki-self-signed-cert = {
    description = "Local TLS certificate for rex.teamraptors.pl";

    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "rex-certs";
      StateDirectoryMode = "0755";
      UMask = "0022";

      ExecStart = pkgs.writeShellScript "generate-rex-cert" ''
        set -eu

        cert=/var/lib/rex-certs/cert.pem
        key=/var/lib/rex-certs/key.pem

        if [ ! -s "$cert" ] || [ ! -s "$key" ]; then
          ${pkgs.openssl}/bin/openssl req \
            -x509 \
            -newkey rsa:3072 \
            -sha256 \
            -days 3650 \
            -nodes \
            -keyout "$key" \
            -out "$cert" \
            -subj "/CN=rex.teamraptors.pl" \
            -addext "subjectAltName=DNS:rex.teamraptors.pl" \
            -addext "basicConstraints=critical,CA:TRUE"

          chown root:nginx "$key"
          chmod 0640 "$key"
          chmod 0644 "$cert"
        fi
      '';
    };
  };

  # Ensure the certificate exists before Nginx starts.
  systemd.services.nginx = {
    requires = [ "rex-nginx-wiki-self-signed-cert.service" ];
    after = [ "rex-nginx-wiki-self-signed-cert.service" ];
  };
}
