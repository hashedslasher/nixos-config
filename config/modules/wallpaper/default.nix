{ config, pkgs, lib, ... }:
let
  cfg = config.modules.wallpaper;
  users = lib.filterAttrs (name: userConfig: userConfig.isAdminUser) config.users.users;
  userNames = lib.attrNames users;

in {
  options.modules.wallpaper = {
    enable = lib.mkEnableOption "Wallpaper service";
  };
  
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mpvpaper
      inotify-tools
    ];
    
    environment.persistence."/persist".users = lib.genAttrs userNames (name: {
      directories = [
        ".cache/wallpaper"
      ];
    });
    
    systemd.user.services.wallpaper = {
      description = "Dynamic Wallpaper Cache and Setter Daemon";
      
      wantedBy = [ "graphical-session.target" ];
      
      partOf = [ "graphical-session.target" ];
      
      after = [ "graphical-session.target" ];
      
      path = with pkgs; [
        mpvpaper
        inotify-tools
        coreutils
        procps
        bash
      ];
      
      serviceConfig = {
        Type = "simple";
        
        ExecStartPre = pkgs.writeShellScript "wallpaper-pre" ''
          ${pkgs.coreutils}/bin/mkdir -p $HOME/.cache/wallpaper
          ${pkgs.coreutils}/bin/mkdir -p $HOME/.config/system
          ${pkgs.coreutils}/bin/touch $HOME/.config/system/wallpaper
        '';
        
        ExecStart = pkgs.writeShellScript "wallpaper-daemon" ''
          THEME_FILE="$HOME/.config/system/wallpaper"
          CACHE_DIR="$HOME/.cache/wallpaper"
          DEFAULT_WALLPAPER="/etc/xdg/assets/wallpaper/default.jpg"
          
          get_wallpaper_path() {
            if [[ -s "$THEME_FILE" ]]; then
              ORIGINAL_PATH="$(cat "$THEME_FILE")"
              FILENAME="''${ORIGINAL_PATH##*/}"
              CACHED="$CACHE_DIR/''${FILENAME}"
              if [[ ! -f "$CACHED" ]]; then
                if [[ -f "$ORIGINAL_PATH" ]]; then
                  rm -f "$CACHE_DIR"/*
                  cp "$ORIGINAL_PATH" "$CACHED"
                  echo "$CACHED"
                else
                  echo "$DEFAULT_WALLPAPER"
                fi
              else
                echo "$CACHED"
              fi
            else
              echo "$DEFAULT_WALLPAPER"
            fi
          }
          SCRIPT_PID=$$
          (
            while true; do
              while [[ ! -f "$THEME_FILE" ]]; do sleep 0.2; done
              inotifywait -qq -e modify,close_write,moved_to,attrib "$THEME_FILE" 2>/dev/null
              sleep 0.5
              pkill -P ''${SCRIPT_PID} mpvpaper 2>/dev/null
            done
          ) &
          
          WATCHER_PID=$!
          trap 'kill $WATCHER_PID 2>/dev/null' EXIT
          
          while true; do
            TARGET_PATH=$(get_wallpaper_path)
            mpvpaper -o "no-audio --loop-playlist --fs --no-border --no-keepaspect" ALL "$TARGET_PATH"
            sleep 1
          done
        '';
        Restart = "always";
        RestartSec = "2s";
      };
    };
  };
}
