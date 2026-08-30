{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{
  imports = [
    ../config/apps
    ../config/modules
  ];
  modules = {
    networking = {
      enable = true;
      vpn.enable = true;
    };
  };

  apps.kodi.enable = true;
  
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
