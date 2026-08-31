{ config, lib, pkgs, pkgs-stable, pkgs-unstable, sddmTheme, ... }:
{

  options.apps.sddm = {
    enable = lib.mkEnableOption "Enable sddm";
  };
  
  config = lib.mkIf config.apps.sddm.enable {
    services.displayManager = {
      defaultSession = "mango";
    };      
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      package = pkgs.kdePackages.sddm;
      theme = sddmTheme.pname;
      extraPackages = sddmTheme.propagatedBuildInputs;
    
      settings = {
        Theme = {
          CursorTheme = "volantes_cursors";
        };
        General = {
          GreeterEnvironment = "QML2_IMPORT_PATH=${sddmTheme}/share/sddm/themes/${sddmTheme.pname}/components/,QT_IM_MODULE=qtvirtualkeyboard";
          InputMethod = "qtvirtualkeyboard";
        };
      };
    };

    
    environment.systemPackages = with pkgs; [
      sddmTheme
    ];
  };
  
}
