{ config, lib, pkgs, pkgs-stable, pkgs-unstable, mango, ... }:
{
  imports = [ ../../modules/wallpaper ];
  
  options.apps.mango = {
    enable = lib.mkEnableOption "Enable mango";
  };
  
  config = lib.mkIf config.apps.mango.enable {
    modules.wallpaper.enable = true;
    #environment.etc."xdg/mango".source = ./config;
    programs.mango = {
      enable = true;
      package = pkgs.mangowc;
    };
  };
}
