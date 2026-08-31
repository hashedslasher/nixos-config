{
  inputs = {
    nixpkgs-stable.url = "nixpkgs/nixos-26.05";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    
    nypkgs = {
      url = "github:yunfachi/nypkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    impermanence.url = "github:nix-community/impermanence";
    mango.url = "github:mangowm/mango";
    musnix.url = "github:musnix/musnix";
    vibepanel.url = "github:prankstr/vibepanel";
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    silentSDDM-stable = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    
    rehomify.url = ./pkgs/rehomify;
    brave-origin.url = ./pkgs/brave-origin;
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nypkgs,
      silentSDDM,
      silentSDDM-stable,
      musnix,
      flake-utils,
      disko,
      impermanence,
      rehomify,
      mango,
      sops-nix,
      brave-origin,
      vibepanel,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      
      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
        overlays = commonOverlays;
      };
      
      pkgs-unstable = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = commonOverlays;
      };

      commonModules = [
        musnix.nixosModules.musnix
        disko.nixosModules.disko
        impermanence.nixosModules.default
        rehomify.nixosModules.rehomify
        mango.nixosModules.mango
        sops-nix.nixosModules.sops
        brave-origin.nixosModules.default
      ];

      commonOverlays = [
        vibepanel.overlays.default
      ];

      mkHost = { hostname, pkgs, systemBuilder, sddmPkg }: systemBuilder {
        inherit system;
        
        pkgs = pkgs;
        
        specialArgs = {
          sddmTheme = sddmPkg.override { theme = "default"; };
          inherit pkgs-stable pkgs-unstable inputs;
          ylib = inputs.nypkgs.lib.${system};
        };

        modules = commonModules ++ [
          ./hosts/${hostname}
          { networking.hostName = hostname; }
          { environment.defaultPackages = lib.mkForce []; }
        ];
      };

      hostDict = builtins.fromJSON (builtins.readFile ./hosts/hosts.json);

      buildConfig = name: channel: mkHost {
        hostname = name;
        pkgs = if channel == "stable" then pkgs-stable else pkgs-unstable;
        systemBuilder = if channel == "stable"
          then nixpkgs-stable.lib.nixosSystem
          else nixpkgs.lib.nixosSystem;
        sddmPkg = if channel == "stable"
          then inputs.silentSDDM-stable.packages.${system}.default
          else inputs.silentSDDM.packages.${system}.default;
      };
    in
    {
      nixosConfigurations = lib.mapAttrs buildConfig hostDict;

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      apps.${system}.default =
        let
          install = pkgs-stable.writeShellApplication {
            name = "install";
            runtimeInputs = [ pkgs-stable.git ];
            text = builtins.readFile ./bin/nix/install.sh;
          };
        in
        {
          type = "app";
          program = "${install}/bin/install";
        };
    };
}
