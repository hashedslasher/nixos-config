{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.impermanence;
  activatedUsers = lib.filter (name: config.users.users.${name}.homeActivate or false) (
    lib.attrNames config.users.users
  );
in
{
  options = {
    impermanence.enable = lib.mkEnableOption "Enable Impermanence";

    users.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.homeActivate = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to enable rehomify and auto-persistence for this user.";
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        security.sudo.extraConfig = ''
          Defaults lecture = never
        '';

        rehomify = {
          enable = lib.mkIf (activatedUsers != [ ]) true;
          users = activatedUsers;
        };

        environment.persistence."/persist" = {
          enable = true;
          hideMounts = true;
          directories = [
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/etc/nixos"
            "/etc/NetworkManager/system-connections"
            "/etc/ssh"
          ];
          files = [
            "/etc/machine-id"
          ];
        };

        boot.initrd.systemd.services."rootfs-cleanup" = {
          wantedBy = [ "initrd.target" ];
          after = [ "initrd-root-device.target" ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir /btrfs_tmp
            mount -o subvol=/ /dev/disk/by-label/nixos /btrfs_tmp
            if [[ -e /btrfs_tmp/root ]]; then
                mkdir -p /btrfs_tmp/old_roots
                timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
                mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
            fi

            delete_subvolume_recursively() {
                IFS=$'\n'
                for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                    delete_subvolume_recursively "/btrfs_tmp/$i"
                done
                btrfs subvolume delete "$1"
            }

            for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
                delete_subvolume_recursively "$i"
            done

            btrfs subvolume create /btrfs_tmp/root
            umount /btrfs_tmp
          '';
        };
      }

      {
        environment.persistence."/persist".users = lib.genAttrs activatedUsers (name: {
          directories = [
            ".local/state/nix/profiles"
            ".config/home-manager"
          ];
        });
      }
    ]
  );
}
