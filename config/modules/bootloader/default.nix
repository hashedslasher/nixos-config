{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        configurationLimit = 5;
      };
      timeout = 0;
    };

  };
  systemd.services.NetworkManager-wait-online.wantedBy = lib.mkForce [ ];
}
