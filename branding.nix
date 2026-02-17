{ config, pkgs, lib, ... }:

let
  dependencies = [ pkgs.gawk pkgs.hostname pkgs.coreutils ];

  preloginScript = pkgs.writeShellScript "prelogin" ''
    export PATH="${lib.makeBinPath dependencies}:$PATH"

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

    get_stats() {
      echo -e "''${TEXT_BOLD}System:''${TEXT_RESET} ''${LOGO_COLOR}$(hostname)''${TEXT_RESET}"
      echo "" 
      
      echo -e "''${TEXT_BOLD}Memory:''${TEXT_RESET}"
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
      
      echo ""
      
      echo -e "''${TEXT_BOLD}Network:''${TEXT_RESET}"
      ${pkgs.iproute2}/bin/ip -4 -o addr show | grep -v " lo " | head -n 3 | while read -r line; do
        IFACE=$(echo "$line" | awk '{print $2}')
        IP=$(echo "$line" | awk '{print $4}' | cut -d'/' -f1)
        printf "  %-6s ''${LOGO_COLOR}%s''${TEXT_RESET}\n" "$IFACE" "$IP"
      done
      
      echo ""
      
      if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
          RUNNING=$(docker ps -q | wc -l)
          if [ "$RUNNING" -gt 0 ]; then
            echo -e "''${TEXT_BOLD}Docker:''${TEXT_RESET}  ''${LOGO_COLOR}$RUNNING running''${TEXT_RESET}"
            docker ps --format "{{.Names}}" | head -n 2 | sed 's/^/  - /'
            [ "$RUNNING" -gt 2 ] && echo "  ...and $(($RUNNING - 2)) more"
          else
            echo -e "''${TEXT_BOLD}Docker:''${TEXT_RESET}  0 running"
          fi
      else
          echo "" 
      fi
    }

    mapfile -t STATS_LINES < <(get_stats)
    mapfile -t LOGO_LINES < <(get_logo)
    
    MAX_LINES=$(( ''${#STATS_LINES[@]} > ''${#LOGO_LINES[@]} ? ''${#STATS_LINES[@]} : ''${#LOGO_LINES[@]} ))
    
    echo ""
    for i in $(seq 0 $((MAX_LINES - 1))); do
      S_LINE="''${STATS_LINES[$i]}"
      L_LINE="''${LOGO_LINES[$i]}"
      
      echo -ne "''${LOGO_COLOR}''${L_LINE}''${TEXT_RESET}"
      echo -ne "\033[28G"
      echo -e "$S_LINE"
    done
    echo ""
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
