{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.modules.bluetooth = {
    enable = lib.mkEnableOption "Enable Bluetooth";
  };

  config = lib.mkIf config.modules.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true; # Show battery charge of Bluetooth devices
        };
      };
    };
  };
}
