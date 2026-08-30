{ config, lib, pkgs, ... }:

let
  adminUsers = lib.filterAttrs (name: userConfig: userConfig.isAdminUser) config.users.users;
  adminUserNames = lib.attrNames adminUsers;
in
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule ({ config, ... }: {
        
        options.isAdminUser = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable the admin option. Only a single user can have this set to true.";
        };

        config = lib.mkIf config.isAdminUser {
          extraGroups = [ "wheel" "nix" ];
        };

      })
    );
  };

  config = {
    assertions = [
      {
        assertion = builtins.length adminUserNames <= 1;
        message = "More than one user has isAdminUser = true: ${builtins.concatStringsSep ", " adminUserNames}. Only a single user can have this enabled.";
      }
    ];

    environment.persistence."/persist".users = lib.genAttrs adminUserNames (name: {
      directories = [
        ".config/sops"
      ];
    });
  };
}
