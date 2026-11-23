{ config, lib, pkgs, ... }:

{
  options.services.uartLogger = {

    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable UART logger with boot retention and timed flush.";
    };

    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/ttyACM0";
      description = "Which port UART sends logs to";
    };

    maxBoots = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = "How many boots logs should last (current boot included)";
    };

    flushInterval = lib.mkOption {
      type = lib.types.str;
      default = "1s";
      description = "Interval of how often the logs should be dumped to file (this value determines the maximum data loss)";
    };
  };

  config =
    let
      cfg = config.services.uartLogger;

      ramDir = "/run/uart-logs";
      diskDir = "/var/log/uart-logs";

      #Writes only new data
      flushScript = pkgs.writeShellScript "uart-log-flush" ''
        set -eu

        SRC="${ramDir}/current.log"
        OFF_FILE="${ramDir}/offset"
        DST="${diskDir}/current.log"

        [ -f "$SRC" ] || exit 0

        # Jeden zrzut naraz (timer vs ExecStopPost)
        exec 9>"${ramDir}/flush.lock"
        ${pkgs.util-linux}/bin/flock 9

        off=$(cat "$OFF_FILE" 2>/dev/null || echo 0)
        size=$(${pkgs.coreutils}/bin/stat -c %s "$SRC")

        if [ "$size" -gt "$off" ]; then
          ${pkgs.coreutils}/bin/tail -c +$((off + 1)) "$SRC" \
            | ${pkgs.coreutils}/bin/head -c $((size - off)) >> "$DST"
          ${pkgs.coreutils}/bin/sync "$DST"   # fsync tylko tego pliku
          echo "$size" > "$OFF_FILE"
        fi
      '';
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.maxBoots >= 2;
          message = "services.uartLogger.maxBoots must be >= 2.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${diskDir} 0755 root root -"
        "d ${ramDir} 0755 root root -"
      ];

      # change files names, once on system boot
      systemd.services.uart-log-rotate = {
        description = "Rotate UART log files (keep last ${toString cfg.maxBoots} boots)";
        wantedBy = [ "multi-user.target" ];
        before = [ "uart-logger.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          LOG_DIR="${diskDir}"
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
        '';
      };

      # data written to RAM, not yet in file
      systemd.services.uart-logger = {
        description = "UART to RAM Logger (flushed to disk periodically)";
        wantedBy = [ "multi-user.target" ];
        after = [ "uart-log-rotate.service" ];
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          ExecStart = pkgs.writeShellScript "uart-logger-start" ''
            set -euo pipefail
            mkdir -p ${ramDir}
            ${pkgs.socat}/bin/socat -u ${lib.escapeShellArg cfg.device},raw - \
              | ${pkgs.gawk}/bin/awk '{print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush()}' \
              >> ${ramDir}/current.log
          '';
          # this part prob won't be used realistically
          ExecStopPost = "-${flushScript}";
          Restart = "always";
          RestartSec = "2s";
          SupplementaryGroups = [ "dialout" ];
        };
      };

      systemd.timers.uart-log-sync = {
        description = "Timer for periodic flush of UART logs to disk (every ${cfg.flushInterval})";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = cfg.flushInterval;
          OnUnitActiveSec = cfg.flushInterval;
          Unit = "uart-log-sync.service";
        };
      };

      systemd.services.uart-log-sync = {
        description = "Flush UART logs from RAM to physical storage";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${flushScript}";
        };
      };
    };
}
