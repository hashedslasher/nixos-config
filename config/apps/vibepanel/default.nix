{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{

  options.apps.vibepanel = {
    enable = lib.mkEnableOption "Enable vibepanel";
  };
  
  config = lib.mkIf config.apps.vibepanel.enable {
    
    environment.etc."xdg/vibepanel".source = ./config;
    
    environment.systemPackages = with pkgs; [
      vibepanel
    ];
  };
}
