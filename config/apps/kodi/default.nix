{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.apps.kodi = {
    enable = lib.mkEnableOption "Enable kodi";
  };
  config = lib.mkIf config.apps.kodi.enable {
    services.xserver.desktopManager.kodi = {
      enable = true;
      package = pkgs.stdenv.mkDerivation {
        name = "kodi-alsa";
        buildCommand = ''
          mkdir -p $out/bin
          ln -s ${pkgs.kodi}/bin/kodi $out/bin/kodi
          wrapProgram $out/bin/kodi --set KODI_AE_SINK ALSA
        '';
        nativeBuildInputs = [ pkgs.makeWrapper ];
      };
    };
    environment.systemPackages = [
      (pkgs.kodi.withPackages (
        kodiPkgs: with kodiPkgs; [
          steam-launcher
        ]
      ))
    ];
  };
}
