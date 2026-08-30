{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{

  options.apps.neovim = {
    enable = lib.mkEnableOption "Enable neovim";
  };
  
  config = lib.mkIf config.apps.neovim.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
