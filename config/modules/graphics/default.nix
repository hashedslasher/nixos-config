{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.modules.graphics = {
    enable = lib.mkEnableOption "Enable graphics module";
  };
  config = lib.mkIf config.modules.graphics.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
    systemd.services.lact = {
      enable = false;

      description = "AMDGPU Control Daemon";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.lact}/bin/lact daemon";
      };
    };
  };
}
