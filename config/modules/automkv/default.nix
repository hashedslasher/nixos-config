{ config, lib, pkgs, pkgs-stable, ... }:

with lib;

let
  cfg = config.services.mkvAutorip;
  ripScript = pkgs.writeShellScript "autorip-makemkv" ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.util-linux}/bin:${pkgs-stable.makemkv}/bin:${pkgs-stable.eject}/bin"
    
    DEVNAME="$1" # e.g., /dev/sr0
    
    exec 9>/tmp/autorip_sr0.lock
    if ! flock -n 9; then
      exit 0
    fi

    echo "DVD detected. Waiting 10 seconds for drive to spin up..."
    sleep 10

    DRIVE_INDEX=$(echo "$DEVNAME" | tr -dc '0-9')
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    RAW_LABEL=$(lsblk -n -o LABEL "$DEVNAME")
    
    if [ -z "$RAW_LABEL" ]; then
      RAW_LABEL="UNKNOWN_DVD"
    fi
    
    CLEAN_LABEL=$(echo "$RAW_LABEL" | tr ' ' '_' | tr -cd 'A-Za-z0-9_-')
    
    BASE_DIR="${cfg.location}"
    
    TARGET_FILE="$BASE_DIR/''${CLEAN_LABEL}_''${TIMESTAMP}.iso"

    echo "Starting backup of $CLEAN_LABEL to $TARGET_FILE..."
    
    mkdir -p "$BASE_DIR"

    if makemkvcon --noscan --decrypt backup disc:"$DRIVE_INDEX" "$TARGET_FILE"; then
      echo "Backup completed successfully."
    else
      echo "MakeMKV encountered an error during backup."
    fi

    echo "Ejecting $DEVNAME..."
    eject "$DEVNAME"
  '';

in {
  options.services.mkvAutorip = {
    enable = mkEnableOption "Automatic MakeMKV DVD Ripper";
    
    boot.kernelModules = [ "sg" ];
    
    user = mkOption {
      type = types.str;
      description = "The user account that will run the systemd service.";
      example = "layton";
    };

    location = mkOption {
      type = types.str;
      description = "The absolute path to the directory where ISOs will be saved.";
      example = "/home/user/Videos/backup";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs-stable; [ makemkv eject util-linux libdvdcss ];

    
    systemd.services."autorip@" = {
      description = "Automatic DVD ISO Ripper on %I";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = "users";
        ExecStart = "${ripScript} /dev/%I";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="block", KERNEL=="sr[0-9]*", ENV{ID_CDROM_MEDIA}=="1", ENV{ID_CDROM_MEDIA_STATE}=="complete", ACTION=="change", TAG+="systemd", ENV{SYSTEMD_WANTS}+="autorip@%k.service"
    '';
  };
}
