{
  globals,
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    {
      programs.nix-index-database.comma.enable = true;
    }
  ];
  # programs.nix-index.enable = true; # disable if nix-index-database is used

  home.packages = with pkgs; [
    nix-derivation
    nix-init
    nix-tree
    # nix-du
    nix-visualize
    nixpacks
    nixos-generators
    nixos-shell
    niv
    nurl
    nvd
    disko
    extra-container
    inputs.nix-alien.packages.${globals.system}.nix-alien
  ];
}
