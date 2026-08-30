{
  config,
  lib,
  pkgs,
  musnix,
  ...
}:
{
  options.modules.audio = {
    base.enable = lib.mkEnableOption "Enable base audio stack";
    advanced.enable = lib.mkEnableOption "Enable advanced audio";
  };

  config = lib.mkMerge [
    (lib.mkIf config.modules.audio.base.enable {
      services.pipewire = {
        enable = true;
        wireplumber.enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    })

    (lib.mkIf config.modules.audio.advanced.enable {
      services.pipewire.jack.enable = true;
      musnix = {
        enable = true;
      };

      environment.systemPackages = with pkgs; [
        rtaudio
      ];
      services.pipewire.extraConfig.pipewire."e30-ii" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
        };
      };
      services.pipewire.wireplumber.extraConfig."e30-ii" = {
        "monitor.alsa.rules" = [
          {
            "matches" = [
              {
                "node.name" = "alsa_output.usb-Topping_E30_II-00.HiFi__Headphones__sink";
                "media.class" = "Audio/Sink";
              }
            ];
            "actions" = {
              "update-props" = {
                "audio.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
                "resample.disable" = true;
                "channelmix.disable" = true;
              };
            };
          }
        ];
      };   
    })
  ];
}
