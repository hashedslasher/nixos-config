{
  description = "Brave Origin Nightly NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        brave-origin-nightly = pkgs.callPackage ./brave-origin-nightly.nix { };
        default = self.packages.${system}.brave-origin-nightly;
      };

      nixosModules = {
        brave-origin-nightly = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.programs.brave-origin-nightly;
          in
          {
            options.programs.brave-origin-nightly = {
              enable = mkEnableOption "Brave Origin Nightly browser";
              
              package = mkOption {
                type = types.package;
                default = self.packages.${pkgs.system}.brave-origin-nightly;
                defaultText = literalExpression "self.packages.\${pkgs.system}.brave-origin-nightly";
                description = "The package to use for Brave Origin Nightly.";
              };
            };

            config = mkIf cfg.enable {
              environment.systemPackages = [ cfg.package ];
            };
          };

        default = self.nixosModules.brave-origin-nightly;
      };
    };
}
