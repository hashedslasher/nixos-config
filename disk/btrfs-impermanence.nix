{ config, lib, ... }:
{
  options.installDisk = lib.mkOption {
    type = lib.types.str;
    description = "The block device to install NixOS to.";
  };

  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = config.installDisk;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                label = "boot";
                name = "ESP";
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };

              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L"
                    "nixos"
                    "-f"
                  ];

                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "subvol=root"
                        "compress=zstd:1"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };

                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "subvol=nix"
                        "compress=zstd:1"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };

                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "subvol=persist"
                        "compress=zstd:1"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };

                    "/swap" = {
                      mountpoint = "/swap";
                      mountOptions = [
                        "subvol=swap"
                        "noatime"
                      ];
                      swap.swapfile = {
                        size = "4G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
    fileSystems."/persist".neededForBoot = true;
  };
}
