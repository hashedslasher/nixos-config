#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/hashedslasher/nixos-config.git"
DEFAULT_HM_URL="https://gitlab.com/hashedslasher/home-manager-config.git"

WORKDIR="/tmp/nixos-install"
FLAKE_DIR="/mnt/etc/nixos"

cleanup () {
    echo "Cleaning up..."
}
trap cleanup EXIT

# ==========================================
# Phase 1: Preparation & Cloning
# ==========================================
whiptail --title "Initialization" --msgbox "Cloning $REPO_URL" 15 60
rm -rf "$WORKDIR"
git clone "$REPO_URL" "$WORKDIR"

# ==========================================
# Phase 2: Gather User Inputs
# ==========================================
mapfile -t hosts < <(nix eval "$WORKDIR#nixosConfigurations" --apply 'builtins.attrNames' --json | jq -r '.[]')

MENU_OPTIONS=()
CREATE_OPT="Create host from profile template"

if [ ${#hosts[@]} -gt 0 ]; then
    for host in "${hosts[@]}"; do
        if [[ -s "$WORKDIR/$host/default.nix" ]]; then
            MENU_OPTIONS+=("$host" "")
        fi
    done
fi
MENU_OPTIONS+=("$CREATE_OPT" "")

host_choice=$(whiptail --title "Host selection" \
    --menu "Select or create a host:" 20 60 10 \
    "${MENU_OPTIONS[@]}" \
    3>&1 1>&2 2>&3) || exit 1

user_name=$(whiptail --inputbox "Enter a username for the primary user" 8 39 --title "Username" 3>&1 1>&2 2>&3) || exit 1

if whiptail --title "Home Manager" --yesno "Install my standalone Home Manager config?" 8 78; then
  hm_url="$DEFAULT_HM_URL"
else
  hm_url="0"
fi

# --- SOPS / Bitwarden Setup ---
handle_sops() {
    session_key=$(whiptail --passwordbox "Enter Bitwarden Master Password to unlock SOPS:" 15 50 3>&1 1>&2 2>&3) || return 1
    
    export BW_SESSION=$(bw unlock "$session_key" --raw)
    if [ -z "$BW_SESSION" ]; then
        whiptail --msgbox "Invalid password or unable to connect to BitWarden" 15 50
        return 1
    fi
    
    bw get password SOPS > /tmp/age-key.txt
    
    PERSIST_SSH_DIR="/mnt/persist/etc/ssh"
    mkdir -p "$PERSIST_SSH_DIR"
    
    SECRETS_YAML="$WORKDIR/secrets.yaml"
    SOPS_YAML="$WORKDIR/.sops.yaml"
    export SOPS_AGE_KEY_FILE=/tmp/age-key.txt
    
    # We need the host_name for SOPS extraction. 
    # If creating a new host, we extract the generic logic or prompt for host early.
    # To keep it simple, we use the host_choice if it exists, otherwise we wait to handle keys.
    local target_host="$host_choice"
    if [[ "$target_host" == "$CREATE_OPT" ]]; then
        target_host=$(whiptail --inputbox "Enter hostname for new host (needed for SOPS)" 8 39 --title "Hostname" 3>&1 1>&2 2>&3) || return 1
        # Export this so create_host doesn't have to ask again
        export PREFILLED_HOSTNAME="$target_host" 
    fi

    whiptail --infobox "Checking SOPS for existing host keys for $target_host..." 15 50
    EXISTING_KEY=$(sops -d --extract "[\"hosts\"][\"$target_host\"][\"private_key\"]" "$SECRETS_YAML" 2>/dev/null || true)
    
    if [[ -n "$EXISTING_KEY" ]]; then
        whiptail --infobox "Existing keys found for $target_host. Restoring..." 15 50
        echo "$EXISTING_KEY" > "$PERSIST_SSH_DIR/ssh_host_ed25519_key"
        sops -d --extract "[\"hosts\"][\"$target_host\"][\"public_key\"]" "$SECRETS_YAML" > "$PERSIST_SSH_DIR/ssh_host_ed25519_key.pub"
        
        chmod 600 "$PERSIST_SSH_DIR/ssh_host_ed25519_key"
        chmod 644 "$PERSIST_SSH_DIR/ssh_host_ed25519_key.pub"
    else
        whiptail --infobox "No existing keys found for $target_host. Generating new pair..." 15 50
        ssh-keygen -t ed25519 -f "$PERSIST_SSH_DIR/ssh_host_ed25519_key" -N ""
        
        NEW_PRIVATE=$(cat "$PERSIST_SSH_DIR/ssh_host_ed25519_key")
        NEW_PUBLIC=$(cat "$PERSIST_SSH_DIR/ssh_host_ed25519_key.pub")
        HOST_AGE_PUB=$(ssh-to-age -i "$PERSIST_SSH_DIR/ssh_host_ed25519_key.pub")
        
        sops -d "$SECRETS_YAML" | \
        yq eval ".hosts.\"$target_host\" = {\"private_key\": \"$NEW_PRIVATE\", \"public_key\": \"$NEW_PUBLIC\"}" - | \
        sops --encrypt /dev/stdin > "$SECRETS_YAML.tmp"
        
        mv "$SECRETS_YAML.tmp" "$SECRETS_YAML"
        
        if ! grep -q "$HOST_AGE_PUB" "$SOPS_YAML"; then
            yq eval ".keys += {\"$target_host\": \"$HOST_AGE_PUB\"}" -i "$SOPS_YAML"
            yq eval ".creation_rules[0].key_groups[0].age += [\"$HOST_AGE_PUB\"]" -i "$SOPS_YAML"
        fi
        
        sops updatekeys "$SECRETS_YAML" -y
        
        git -C "$WORKDIR" add secrets.yaml .sops.yaml
        git -C "$WORKDIR" commit -m "vault: backup ssh keys and register age key for $target_host" || true
    fi
    return 0
}

IS_OWNER=false

# Ask for SOPS bypass logic[cite: 1]
if whiptail --yesno "Retrieve SOPS key? (Select No to bypass if you are installing my config)" 15 50; then
    while true; do
        if handle_sops; then
            IS_OWNER=true
            break
        else
            if ! whiptail --yesno "Retry SOPS Bitwarden login?" 15 50; then
                break
            fi
        fi
    done
fi

# --- Password Setup (Only runs if SOPS was bypassed or failed) ---
hashed_password_str=""

if [[ "$IS_OWNER" == false ]]; then
    while true; do
        password=$(whiptail --passwordbox "Enter a password for $user_name (Outsider Setup):" 15 50 3>&1 1>&2 2>&3) || {
            whiptail --msgbox "You must set a password to avoid being locked out." 15 50
            continue
        }
        
        password_check=$(whiptail --passwordbox "Confirm password:" 15 50 3>&1 1>&2 2>&3) || continue
        
        if [[ "$password" == "$password_check" && -n "$password" ]]; then
            hash=$(nix run nixpkgs#mkpasswd -- -m SHA-512 "$password")
            hashed_password_str="hashedPassword = \"$hash\";"
            break
        else
            whiptail --msgbox "Passwords do not match or are empty. Try again." 15 50
        fi
    done
fi

# --- Disk Selection ---
DRIVE_ARRAY=()
while read -r name size type; do
    if [[ "$type" == "part" ]]; then
        DRIVE_ARRAY+=(" $name" "$size")
    elif [[ "$type" == "disk" ]]; then
        DRIVE_ARRAY+=("$name" "$size")
    fi
done < <(lsblk -lno NAME,SIZE,TYPE)

if [[ ${#DRIVE_ARRAY[@]} -eq 0 ]]; then
    echo "Error: No drives found."
    exit 1
fi

disk_name=$(whiptail --title "Disk Selection" \
                  --menu "Choose a drive or partition:" \
                  15 50 6 \
                  "${DRIVE_ARRAY[@]}" \
                  3>&1 1>&2 2>&3) || exit 1

disk_name=$(echo "$disk_name" | xargs)
install_drive="/dev/$disk_name"

if ! whiptail --yesno "This will wipe $install_drive. Continue?" 15 50 --defaultno; then
  exit 1
fi

# ==========================================
# Phase 3: Config Generation
# ==========================================
create_host() {
    # If we already asked for the hostname during SOPS, use it. Otherwise, prompt.
    if [[ -n "${PREFILLED_HOSTNAME:-}" ]]; then
        host_name="$PREFILLED_HOSTNAME"
    else
        host_name=$(whiptail --inputbox "Enter hostname for new host" 8 39 --title "Hostname" 3>&1 1>&2 2>&3) || exit 1
    fi

    channel_val=$(whiptail --title "Packages" \
        --menu "Select primary package type" 20 60 10 \
        "stable" "" \
        "unstable" "" \
        3>&1 1>&2 2>&3) || exit 1

    jq --arg h "$host_name" --arg c "$channel_val" \
        '.[$h] = $c' "$WORKDIR/hosts.json" >"$WORKDIR/hosts.tmp.json" &&
        mv "$WORKDIR/hosts.tmp.json" "$WORKDIR/hosts.json"

    mapfile -t profiles < <(find "$WORKDIR/profiles" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
    
    PROFILE_OPTS=()
    for prof in "${profiles[@]}"; do
        PROFILE_OPTS+=("$prof" "")
    done

    profile=$(whiptail --title "Profile selection" \
        --menu "Select profile:" 20 60 10 \
        "${PROFILE_OPTS[@]}" \
        3>&1 1>&2 2>&3) || exit 1

    persist_home_str=""
    hm_activate_str=""

    if whiptail --title "Persistence" --yesno "Persist main user home directory?" 8 50; then
        persist_home_str="environment.persistence.\"/persist\" = {
    directories = [
      \"/home/$user_name\"
    ];
  };"
    elif [[ "$hm_url" != "0" ]]; then
        hm_activate_str="homeActivate = true;"
    fi

    mkdir -p "$WORKDIR/hosts/$host_name"

    # Only injects the password string if it's an outsider. If it's you (SOPS owner), this remains empty
    # so that sops-nix can map it without default.nix overriding it.
    cat <<EOF >"$WORKDIR/hosts/$host_name/default.nix"
{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../disk/btrfs-impermanence.nix
    ../../profiles/$profile
  ];

  networking.hostName = "$host_name";
  mySystem.installDisk = "$install_drive";

  users.users.$user_name = {
    isNormalUser = true;
    description = "$user_name";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    $hashed_password_str
    $hm_activate_str
  };

  $persist_home_str

  system.stateVersion = "25.05";
}
EOF
}

if [[ "$host_choice" == "$CREATE_OPT" ]]; then
  create_host
else
  # Using an existing host. We need to inject the disk and the outsider password if applicable.
  if [[ -n "${PREFILLED_HOSTNAME:-}" ]]; then
      host_name="$PREFILLED_HOSTNAME"
  else
      host_name="$host_choice"
  fi
  
  HOST_DIR="$WORKDIR/hosts/$host_name"
  sed -i "s|mySystem.installDisk = \".*\";|mySystem.installDisk = \"$install_drive\";|" "$HOST_DIR/default.nix"
  
  # Inject the password for outsiders installing a pre-existing host profile
  if [[ "$IS_OWNER" == false && -n "$hashed_password_str" ]]; then
      sed -i "s|hashedPassword = \".*\";|$hashed_password_str|" "$HOST_DIR/default.nix"
  fi
fi

HOST_DIR="$WORKDIR/hosts/$host_name"
whiptail --title "Installing" --infobox "Generating hardware config..." 15 50
nixos-generate-config --show-hardware-config --no-filesystems >"$HOST_DIR/hardware-configuration.nix"

git -C "$WORKDIR" add .

# ==========================================
# Phase 4 & 5: Format and Install
# ==========================================
whiptail --title "Installing" --infobox "Formatting disk with Disko..." 15 50
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
    --yes-wipe-all-disks \
    --mode disko \
    --flake "$WORKDIR#$host_name"

whiptail --title "Installing" --infobox "Installing NixOS..." 15 50
mkdir -p /mnt/etc
cp -r "$WORKDIR" "$FLAKE_DIR"
sudo nixos-install --flake "$FLAKE_DIR#$host_name" --no-root-passwd

# ==========================================
# Phase 6: Home Manager
# ==========================================
if [[ "$hm_url" != "0" ]]; then
    whiptail --title "Installing" --infobox "Cloning $hm_url..." 15 50
    PERSIST_HOME="/mnt/persist/home/$user_name"

    mkdir -p "$PERSIST_HOME/.config"
    mkdir -p "$PERSIST_HOME/.local/state/nix/profiles"

    git clone "$hm_url" "$PERSIST_HOME/.config/home-manager"

    whiptail --title "Installing" --infobox "Installing home manager..." 15 50
    
    nixos-enter -- su - "$user_name" <<EOF
set -e
nix run home-manager/release-25.05 \
  --extra-experimental-features "nix-command flakes" \
  -- switch --flake "/persist/home/$user_name/.config/home-manager"
EOF

    if [ -d "/mnt/home/$user_name/.local/state/nix/profiles/" ]; then
        cp -a "/mnt/home/$user_name/.local/state/nix/profiles/"* "$PERSIST_HOME/.local/state/nix/profiles/" 2>/dev/null || true
    fi
    nixos-enter --command "chown -R $user_name:users /persist/home/$user_name"
fi

whiptail --title "Complete" --msgbox "Installation complete! You can now reboot." 15 50
