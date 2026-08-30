{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{

  options.apps.quickshellBar = {
    enable = lib.mkEnableOption "Enable quickshell bar";
  };
  
  config = lib.mkIf config.apps.quickshellBar.enable {
    environment.etc."xdg/bar".source = ./config;
    
    environment.systemPackages = with pkgs; [
      quickshell
    ];
  };
}
