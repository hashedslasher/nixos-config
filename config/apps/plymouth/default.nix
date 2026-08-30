{ config, lib, pkgs, pkgs-stable, pkgs-unstable, ... }:
{
  options.apps.plymouth = {
    enable = lib.mkEnableOption "Enable kodi module";
  };
  config = lib.mkIf config.apps.plymouth.enable {
    boot = { 
      plymouth = {
        enable = true;
        theme = "loader";
        themePackages = [
          (pkgs.adi1090x-plymouth-themes.override {
            selected_themes = [ "loader" ];
          })
        ];
      };
      initrd.kernelModules = [ 
        "amdgpu"
      ];
      
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "systemd.show_status=auto"
      ];
    };
  };
}
