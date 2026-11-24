{ config, lib, pkgs, ... }:

{
  options.services.uartLogger = {

    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable UART logger with boot retention.";
    };

    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/ttyACM0";
      description = "Port on which UART sends logs";
    };

    maxBoots = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = "For how many boots keep logs (current included)";
    };
  };

  config =
    let
      cfg = config.services.uartLogger;
      logDir = "/var/log/uart-logs";
      logFile = "${logDir}/current.log";
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.maxBoots >= 2;
          message = "max boots must be >= 2.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${logDir} 0755 root root -"
      ];

      systemd.services.uart-log-rotate = {
        description = "Rotate UART log files (keep last ${toString cfg.maxBoots} boots)";
        wantedBy = [ "multi-user.target" ];
        before = [ "uart-logger.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          LOG_DIR="${logDir}"
          mkdir -p "$LOG_DIR"

          OLDEST_BOOT=$(( ${toString cfg.maxBoots} - 1 ))
          rm -f "$LOG_DIR/boot_$OLDEST_BOOT.log"

          i=$(( ${toString cfg.maxBoots} - 2 ))
          while [ $i -ge 1 ]; do
            prev=$((i - 1))
            if [ $prev -eq 0 ]; then
              [ -f "$LOG_DIR/current.log" ] && mv "$LOG_DIR/current.log" "$LOG_DIR/boot_$i.log"
            else
              [ -f "$LOG_DIR/boot_$prev.log" ] && mv "$LOG_DIR/boot_$prev.log" "$LOG_DIR/boot_$i.log"
            fi
            i=$((i - 1))
          done

          touch "$LOG_DIR/current.log"

          # fsync katalogu i pliku: zmiany nazw przetrwają utratę zasilania
          ${pkgs.coreutils}/bin/sync "$LOG_DIR" "$LOG_DIR/current.log"
        '';
      };

      systemd.services.uart-logger = {
        description = "UART to File Logger";
        wantedBy = [ "multi-user.target" ];
        after = [ "uart-log-rotate.service" ];
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          ExecStart = pkgs.writeShellScript "uart-logger-start" ''
            set -euo pipefail
            ${pkgs.socat}/bin/socat -u ${lib.escapeShellArg cfg.device},raw,echo=0,hupcl=0 - \
              | ${pkgs.gawk}/bin/awk '{gsub(/\r/, ""); print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush()}' \
              | ${pkgs.socat}/bin/socat -u - open:${logFile},creat,append,o-dsync
          '';
          Restart = "always";
          RestartSec = "2s";
          SupplementaryGroups = [ "dialout" ];
        };
      };
    };
}
