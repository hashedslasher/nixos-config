{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{


  options.apps.thunar = {
    enable = lib.mkEnableOption "Enable thunar";
  };
  
  config = lib.mkIf config.apps.thunar.enable {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-volman
        thunar-archive-plugin
        thunar-media-tags-plugin
      ];
    };
    
    services.udisks2.enable = true;
    services.tumbler.enable = true;
    services.gvfs.enable = true;
    
    environment.systemPackages = with pkgs; [
      file-roller
      librsvg
    ];
  };
}
