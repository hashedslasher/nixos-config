{
  config,
  pkgs,
  inputs,
  lib,
  rehomify,
  ylib,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ../../disk/btrfs-impermanence.nix
    ../../profiles/laptop.nix
  ] ++ ylib.umport {
    paths = [
      ../../config/modules
      ../../config/apps
    ];
    recursive = false;
  };

  sops.secrets.layton-password.neededForUsers = true;
  users.users.layton = {
    description = "Layton";
    isNormalUser = true;
    isAdminUser = true;
    homeActivate = true;
    hashedPassword = "$6$QFUo3vQDfJwjRXOb$65bJI4qOxKddTIsrXvSJcvQKhz9FlxI7v7aBtPSkgi6zsfNdlb6SDK622s5e8YXFcVAWGfFWLwNonfVuue4jU.";
    #hashedPasswordFile = config.sops.secrets.layton-password.path;
    extraGroups = [
      "networkmanager"
      "qemu"
      "jackaudio"
      "audio"
      "libvirtd"
      "rtkit"
      "fuse"
    ];
    packages = with pkgs; [
    ];
    shell = pkgs.zsh;
  };
  
  environment.systemPackages = with pkgs; [
  ];
  
  installDisk = "/dev/nvme0n1";
  impermanence.enable = true;
  system.stateVersion = "25.05";
}
