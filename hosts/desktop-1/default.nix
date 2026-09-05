{
  config,
  pkgs,
  inputs,
  lib,
  rehomify,
  pkgs-stable,
  ylib,
  ...
}:
{

  # Import essentials and the desktop profile
  imports = [
    ./hardware-configuration.nix
    ../../disk/btrfs-impermanence.nix
    ../../profiles/desktop.nix
  ] ++ ylib.umport {
    paths = [
      ../../config/modules
      ../../config/apps
    ];
    recursive = false;
  };
  
  # Machine specific configuration
  nix.settings.trusted-users = [ "layton" ];
  sops.secrets.layton-password.neededForUsers = true;
  users.users.layton = {
    description = "Layton";
    isNormalUser = true;
    isAdminUser = true;
    homeActivate = true;
    hashedPasswordFile = config.sops.secrets.layton-password.path;
    extraGroups = [
      "networkmanager"
      "qemu"
      "jackaudio"
      "audio"
      "libvirtd"
      "rtkit"
      "fuse"
      "video"
      "scanner"
      "lp"
      "lpadmin"
      "dialout"
    ];

    packages = with pkgs; [
    ];
    shell = pkgs.zsh;
  };

  xdg.portal.configPackages = [
    pkgs.kdePackages.plasma-bigscreen
    pkgs.kdePackages.kwin
  ];
  
  services.printing = {
    enable = true;
    drivers = with pkgs-stable; [
      cups-filters
      cups-browsed
      hplip
    ];
  };
  
  services.avahi = {
    enable = true;
    nssmdns = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  services.flatpak.enable = true;
  services.usbmuxd.enable = true;

  hardware.openrazer = {
    users = [ "layton" ];
    enable = true;
  };
  
  services.mkvAutorip = {
    enable = false;
    user = "layton";
    location = "/home/layton/persistent/isos";
  };
  
  
  networking.firewall = {
    allowedTCPPorts = [ 5900 5353 9100 11434 631 ];
    allowedUDPPorts = [ 5900 5353 9100 11434 5353 631 ];
  };
  programs.nix-ld.enable = true; 

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs-stable.hplipWithPlugin pkgs-stable.sane-airscan ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      simple-scan = prev.simple-scan.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];
        postInstall = (old.postInstall or "") + ''
          wrapProgram $out/bin/simple-scan \
            --prefix LD_LIBRARY_PATH : "${final.hplipWithPlugin}/lib/sane" \
            --prefix SANE_CONFIG_DIR : "${final.sane-backends}/etc/sane.d"
        '';
      });
    })
  ];

  services.udev.extraRules = ''
    ENV{DEVNAME}!="", ENV{libsane_matched}=="yes", RUN+="${pkgs-stable.acl}/bin/setfacl -m g:scanner:rw $env{DEVNAME}"
  '';

  services.udev.packages = [ pkgs-stable.hplipWithPlugin ];
  
  environment.systemPackages = with pkgs-stable; [
    libdvdcss
    libimobiledevice
    hplip
    simple-scan
    #kdePackages.plasma-bigscreen
    #kdePackages.plasma-workspace
    #kdePackages.kwin
    #pinnacle
    polychromatic
  ];
  
  fileSystems."/mnt/tsb-2tb" = {
    device = "/dev/disk/by-uuid/ce5402f2-c32b-4b3b-b43a-80bc395b47b0";
    fsType = "btrfs";
    options = [
      "nofail"
      "x-systemd.device-bound"
      "noatime"
      "x-gvfs-show"
      "x-gvfs-name=tsb-2tb"
    ];
  };
  
  # DO NOT CHANGE
  installDisk = "/dev/nvme0n1";
  impermanence.enable = true;
  system.stateVersion = "25.05";
}
