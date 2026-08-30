{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{
  imports = [
    ../config/apps
    ../config/modules
  ];

  apps.neovim.enable = true;

  modules = {
    networking = {
      enable = true;
      vpn.enable = true;
    };
    
    virtualization = {
      podman.enable = true;
    };
  };
  
  #services.jellyfin.enable = true;
  
  networking.firewall = {
    allowedTCPPorts = [ 22 8096 111 2049 4000 4001 4002 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 ];
  }; 
  
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
