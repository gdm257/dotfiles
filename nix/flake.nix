{
  description = "All-in-One Nix dotfiles";

  inputs = {
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.flake-compat.follows = "flake-compat";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.inputs.nix-index-database.follows = "nix-index-database";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/2505.7.0";
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
    proxmox-nixos.inputs.flake-compat.follows = "flake-compat";
  };

  outputs = inputs @ {
    self,
    flake-compat,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nix-index-database,
    nix-alien,
    nix-flatpak,
    nix-vscode-extensions,
    nixos-wsl,
    proxmox-nixos,
    ...
  }: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;

    # Global variables
    readJSON = path: builtins.fromJSON (builtins.readFile path);
    baseConfig = readJSON ./config.default.json;
    customConfig =
      if builtins.pathExists ./config.json
      then readJSON ./config.json
      else {};
    mergedConfig = nixpkgs.lib.recursiveUpdate baseConfig customConfig;
    config =
      mergedConfig // {
        hostname =
          if mergedConfig ? hostname then mergedConfig.hostname
          else
            if builtins.getEnv "HOSTNAME" != "" then builtins.getEnv "HOSTNAME"
            else "nixos"
        ;
      }
    ;
    globals = config;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    nixosConfigurations = {
      # Available through 'nixos-rebuild --flake .#your-hostname' (i.e. globals.hostname)
      ${globals.hostname} = nixpkgs.lib.nixosSystem {
        system = globals.system;
        specialArgs = {inherit inputs outputs globals;};
        modules = [
          # > Our main nixos configuration file <
          ./nixos/configuration.nix
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username'
    homeConfigurations = {
      "${globals.username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = globals.system; # Home-manager requires 'pkgs' instance
          overlays = [
            self.overlays.additions
            self.overlays.modifications
          ];
          config.allowUnfree = true;
        };
        extraSpecialArgs = {inherit inputs outputs globals;};
        modules = [
          # > Our main home-manager configuration file <
          ./home-manager/home.nix
        ];
      };
    };
  };
}
