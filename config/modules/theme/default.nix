{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ...}:
{
  environment.etc."xdg/assets".source = ./assets;
  
  fonts.packages = with pkgs; [
    pkgs.nerd-fonts.blex-mono
    pkgs.nerd-fonts.terminess-ttf
    pkgs.nerd-fonts.jetbrains-mono
    
  ];
  
  fonts.fontconfig.enable = true;
  fonts.fontconfig.antialias = true;
  fonts.fontconfig.hinting = {
    enable = true;
    style = "full";
  };
  
  fonts.fontconfig.subpixel = {
    lcdfilter = "default";
    rgba = "rgb";
  };
  
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gtk2";
  };
  
  environment.systemPackages = with pkgs; [
    pywal
    gtk2
    gtk3
    gtk4
    volantes-cursors
    kdePackages.qt6gtk2
    glib
  ];
}
