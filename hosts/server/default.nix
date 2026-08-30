{
  config,
  pkgs,
  inputs,
  lib,
  rehomify,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../disk/btrfs-impermanence.nix
    
    ../../config/modules

    ../../profiles/server.nix
  ];
  
  sops.secrets.archon-password.neededForUsers = true;
  
  users.users.archon = {
    description = "archon";
    isNormalUser = true;
    isAdminUser = true;
    homeActivate = true;
    hashedPassword = config.sops.secrets.archon-password.path;
    extraGroups = [
      "networkmanager"
      "cdrom"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
  ];
  
  environment.persistence."/persist" = {
    directories = [
      {
        directory = "/srv/nfs/media";
        user = "archon";
        group = "users";
        mode = "u=rwx,g=rwx,o=";
      }
    ];
    files = [
    ];
    users.archon.directories = [
      ".ssh"
    ];
  };

  networking.networkmanager.ensureProfiles.profiles = {
    "Wired Connection 1" = {
      connection = {
        id = "Wired Connection 1";
        interface-name = "enp3s0";
        type = "ethernet";
        autoconnect = true;
      };
      ipv4 = {
        method = "manual";
        addresses = "192.168.1.158/24";
        gateway = "192.168.1.1";
        dns = "8.8.8.8";
      };
    };
  };

  services.nfs.server = {
    enable = true;
    
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
    
    exports = ''
      /srv/nfs/media  192.168.1.0/24(ro,sync,no_subtree_check,insecure,all_squash,anonuid=1000,anongid=100)
    '';
  };

  fileSystems."/mnt/WD-2TB" = {
    device = "/dev/disk/by-uuid/f5cdfdf2-38b5-4940-8d92-1e7d08e45247";
    fsType = "btrfs";
    options = [
      "nofail"
      "x-systemd.device-bound"
      "noatime"
      "x-gvfs-show"
      "x-gvfs-name=External HDD"
    ];
  };
  
  impermanence.enable = true;
  installDisk = "/dev/sda";
  system.stateVersion = "25.05";
}
