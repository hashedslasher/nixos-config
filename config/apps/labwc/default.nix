{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{
  imports = [ ../../modules/wallpaper ];

  options.apps.labwc = {
    enable = lib.mkEnableOption "Enable labwc";
  };
  
  config = lib.mkIf config.apps.labwc.enable {
    modules.wallpaper.enable = true;
    environment.etc."xdg/labwc".source = ./config;
    programs.labwc.enable = true;
  };
}
