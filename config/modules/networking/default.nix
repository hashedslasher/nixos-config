{
  config,
  lib,
  pkgs,
  ...
}:
let 
  nixosVersion = pkgs.lib.version;
in
{
  options.modules.networking = {
    enable = lib.mkEnableOption "Enable NetworkManager";
    vpn.enable = lib.mkEnableOption "Enable VPN";
  };

  config = lib.mkMerge [
    (lib.mkIf config.modules.networking.enable {
      networking.networkmanager.enable = true;
      services.openssh.enable = true;
    })

    (lib.mkIf config.modules.networking.vpn.enable {
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };

      networking.nameservers = [
        "1.1.1.1#one.one.one.one"
        "1.0.0.1#one.one.one.one"
      ];

      services.resolved = {
        enable = true;
        settings.Resolve = {
          dnssec = "true";
          domains = [ "~." ];
          fallbackDns = [
            "1.1.1.1#one.one.one.one"
            "1.0.0.1#one.one.one.one"
          ];
          dnsovertls = "true";
        };
      };


      services.mullvad-vpn = {
        enable = true;
      } // lib.optionalAttrs (lib.versionAtLeast nixosVersion "26.11") {
        gui.enable = true;
      };
    })
  ];
}
