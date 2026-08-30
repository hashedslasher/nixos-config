{config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{

  options.apps.walker = {
    enable = lib.mkEnableOption "Enable walker";
  };
  
  config = lib.mkIf config.apps.walker.enable {
    environment.etc."xdg/walker".source = ./config;
    
    services.elephant.enable = true;
    
    environment.systemPackages = with pkgs; [
      walker
    ];
  };
}
