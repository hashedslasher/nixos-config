{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ylib, ... }:
{
  imports = ylib.umport {
    paths = [
      ../config/modules
      ../config/apps
    ];
    recursive = false;
  };

  apps = {
    vibepanel.enable = true;
    kodi.enable = true;
    labwc.enable = true;
    mango.enable = true;
    neovim.enable = true;
    plymouth.enable = true;
    sddm.enable = true;
    thunar.enable = true;
    walker.enable = true;
  };
  
  modules = {
    audio = {
      base.enable = true;
      advanced.enable = true;
    };
    bluetooth.enable = true;
    gaming.enable = true;
    graphics.enable = true;
    networking = {
      enable = true;
      vpn.enable = true;
    };
    virtualization = {
      virt-manager.enable = true;
      podman.enable = true;
    };
  };
  
  
  security.rtkit.enable = true;
  
  programs.zsh = {
    enable = true;
  };
  
  services.udisks2.enable = true;
  
  environment.systemPackages = with pkgs; [
    #Apps
    mpv
    wezterm
    resources
    brave-origin
  
    wget
    git
    unzip
    tree
    sops
    
    #Utils
    bindfs
    grim
    slurp
    playerctl
    wlr-randr
    ripgrep
    wl-clipboard
    lm_sensors
    sysstat
  ];


  environment.persistence."/persist" = {
    directories = [
      "/etc/mullvad-vpn"
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
    ];
    files = [
    ];
  };
}
