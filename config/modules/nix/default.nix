{
  config,
  lib,
  ...
}:
{
  users.groups.nix = { };

  systemd.tmpfiles.settings."10-nixos-directory"."/etc/nixos".Z = {
    mode = "2770";
    group = "nix";
  };

  nix.settings.use-xdg-base-directories = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
