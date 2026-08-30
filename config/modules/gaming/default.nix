{
  config,
  pkgs,
  lib,
  inputs,
  nixos-rocksmith,
  ...
}:
{
  options.modules.gaming = {
    enable = lib.mkEnableOption "Enable gaming module";
  };
  config = lib.mkIf config.modules.gaming.enable {
    programs.steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
    programs.gamescope = {
      enable = true;
      #package = pkgs.gamescope.overrideAttrs (_: {
      #  NIX_CFLAGS_COMPILE = [ "-fno-fast-math" ];
      #});
    };
    hardware.steam-hardware.enable = true;
    boot.blacklistedKernelModules = [
      "xpad"
      "hid_xpadneo"
    ];
  };
}
