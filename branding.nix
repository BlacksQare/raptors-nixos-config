{ config, pkgs, lib, ... }:

let
  dependencies = [ pkgs.gawk pkgs.hostname pkgs.coreutils pkgs.docker pkgs.ncurses];

  preloginScript = pkgs.writeShellScript "prelogin" ''
  export PATH="${lib.makeBinPath dependencies}:$PATH"
  (return 0 2>/dev/null) && _SOURCED=1 || _SOURCED=0

  STATS_COL=28
  NET_MAX=3
  DOCKER_MAX=5

  set_orange_prompt() {
    PS1='\[\033[38;5;202m\][\u@\h:\w]\$ \[\033[0m\]'
  }

  if [[ "$PROMPT_COMMAND" != *set_orange_prompt* ]]; then
    PROMPT_COMMAND="set_orange_prompt;$PROMPT_COMMAND"
  fi

  LOGO_COLOR='\033[38;5;202m'
  TEXT_BOLD='\033[1m'
  TEXT_RESET='\033[0m'

  get_logo() {
    cat << "EOF"
                      ...
                  ...
              ..::.
  ..::::.   .:%::.%:.
  :%%%%%%%. :%%%%%:.
  ...:%%%:..%%%%%:
      :%%.:%%%%%%%.
        .%%%%%:..:%:
        .::.:%..%: :%
          :.:  :.    .%.
        . .: .%      :%
        :%:... :     .%%:
    ......           ::..
  EOF
  }

  get_ram_line() {
    awk -v color="$LOGO_COLOR" -v reset="$TEXT_RESET" '
      /MemTotal/ {total=$2}
      /MemFree/ {free=$2}
      /Buffers/ {buffers=$2}
      /^Cached/ {cached=$2}
      /SReclaimable/ {sreclaim=$2}
      END {
        used = total - free - buffers - cached - sreclaim
        used_gb = used / 1024 / 1024
        total_gb = total / 1024 / 1024
        printf "  %-6s %s%.1fGi%s / %.1fGi\n", "RAM", color, used_gb, reset, total_gb
      }' /proc/meminfo
  }

  get_net_lines() {
    ${pkgs.iproute2}/bin/ip -4 -o addr show \
      | grep -v " lo " \
      | head -n ${toString 3} \
      | awk -v c="$LOGO_COLOR" -v r="$TEXT_RESET" '
          { ip=$4; sub(/\/.*/, "", ip); printf "  %-6s " c "%s" r "\n", $2, ip }'
  }

  get_docker_lines() {
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      RUNNING=$(docker ps -q | wc -l)
      if [ "$RUNNING" -gt 0 ]; then
        echo -e "''${TEXT_BOLD}Docker:''${TEXT_RESET}  ''${LOGO_COLOR}$RUNNING running''${TEXT_RESET}"
        docker ps --format "{{.Names}}" | head -n "$DOCKER_MAX" | sed 's/^/  - /'
        [ "$RUNNING" -gt "$DOCKER_MAX" ] && echo "  ...and $(($RUNNING - $DOCKER_MAX)) more"
      else
        echo -e "''${TEXT_BOLD}Docker:''${TEXT_RESET}  0 running"
      fi
    else
      echo ""
    fi
  }

  build_stats_lines() {
    {
      echo -e "''${TEXT_BOLD}System:''${TEXT_RESET} ''${LOGO_COLOR}$(hostname)''${TEXT_RESET}"
      echo ""
      echo -e "''${TEXT_BOLD}Memory:''${TEXT_RESET}"
      get_ram_line
      echo ""
      echo -e "''${TEXT_BOLD}Network:''${TEXT_RESET}"
      mapfile -t _net < <(get_net_lines)
      for i in $(seq 0 $((NET_MAX - 1))); do
        if [ "$i" -lt "''${#_net[@]}" ]; then
          echo -e "''${_net[$i]}"
        else
          echo "  "
        fi
      done
      echo ""
      get_docker_lines
    }
  }

  render_full() {
    mapfile -t STATS_LINES < <(build_stats_lines)
    mapfile -t LOGO_LINES < <(get_logo)

    MAX_LINES=$(( ''${#STATS_LINES[@]} > ''${#LOGO_LINES[@]} ? ''${#STATS_LINES[@]} : ''${#LOGO_LINES[@]} ))

    echo ""
    for i in $(seq 0 $((MAX_LINES - 1))); do
      S_LINE="''${STATS_LINES[$i]}"
      L_LINE="''${LOGO_LINES[$i]}"
      echo -ne "''${LOGO_COLOR}''${L_LINE}''${TEXT_RESET}"
      echo -ne "\033[''${STATS_COL}G"
      echo -e "$S_LINE"
    done
    echo ""

    RAM_ROW=-1
    NET_HEADER_ROW=-1
    for idx in $(seq 0 $(( ''${#STATS_LINES[@]} - 1 ))); do
      if [ "$RAM_ROW" -lt 0 ] && [[ "''${STATS_LINES[$idx]}" == "  RAM"* ]]; then
        RAM_ROW=$((1 + idx))
      fi
      if [ "$NET_HEADER_ROW" -lt 0 ] && [[ "''${STATS_LINES[$idx]}" == *"Network:"* ]]; then
        NET_HEADER_ROW=$((1 + idx))
      fi
    done

    NET_DATA_ROW=$((NET_HEADER_ROW + 1))
    PROMPT_ROW=$((1 + MAX_LINES + 1))
  }

  update_ram_only() {
    [ "$RAM_ROW" -ge 0 ] || return 0
    tput cup "$RAM_ROW" "$STATS_COL"
    tput el
    get_ram_line | tr -d '\n'
  }

  update_network_only() {
    [ "$NET_DATA_ROW" -ge 0 ] || return 0
    mapfile -t _net < <(get_net_lines)
    for i in $(seq 0 $((NET_MAX - 1))); do
      tput cup $((NET_DATA_ROW + i)) "$STATS_COL"
      tput el
      if [ "$i" -lt "''${#_net[@]}" ]; then
        echo -ne "''${_net[$i]}"
      else
        echo -ne "  "
      fi
    done
  }

  run_once() {
    render_full
  }

  run_refresh_getty() {
    clear
    tput civis 2>/dev/null || true
    render_full

    while true; do
      update_ram_only
      update_network_only

      tput cup "$PROMPT_ROW" "$STATS_COL"
      tput el
      echo -ne "''${TEXT_BOLD}Press Enter to continue...''${TEXT_RESET}"

      if read -r -t 1 _line; then
        break
      fi
    done

    tput cnorm 2>/dev/null || true
    echo ""
  }

  if [ "''${_SOURCED}" -eq 1 ]; then
    run_once
    return 0 2>/dev/null || exit 0
  else
    run_refresh_getty
  fi
'';
in
{
  services.getty.greetingLine = lib.mkForce "";
  services.getty.helpLine = lib.mkForce "";

  systemd.services."autovt@".serviceConfig = {
    TTYVTDisallocate = "no";

    StandardOutput = "tty";
    StandardInput = "tty";

    ExecStartPre = [ 
      "${pkgs.bash}/bin/sh -c '${preloginScript} > /dev/%I'" 
    ];
  };

  systemd.services."getty@".serviceConfig = {
    TTYVTDisallocate = "no";
    StandardOutput = "tty";
    StandardInput = "tty";
    ExecStartPre = [ 
      "${pkgs.bash}/bin/sh -c '${preloginScript} > /dev/%I'" 
    ];
  };

  programs.bash = {
    enable = true;
    
    interactiveShellInit = ''
      source ${preloginScript}
    '';
  };
}
