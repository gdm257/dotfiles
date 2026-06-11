# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  globals,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # TODO: You should munually generate (nixos-generate-config) hardware configuration
    (if globals.isNixosWsl then ./wsl.nix else ./hardware-configuration.nix)

    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # Or modules from your own flake exports (from modules/nixos):
    # outputs.nixosModules.my-module

    # You can also split up your configuration and import pieces of it here:
    ./nixpkgs.nix
    ./nix.nix
    ./networking.nix
    ./ssh.nix
    ./users.nix

    (if globals.isNixosWsl || globals.isPersonalComputer then ./virtualisation.nix else {})

    (if globals.isDesktop then inputs.nix-flatpak.nixosModules.nix-flatpak else {})
    (
      if globals.isDesktop
      then {
        xdg.portal= {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-wlr
            # xdg-desktop-portal-kde
            # xdg-desktop-portal-gnome
            # xdg-desktop-portal-gtk
          ];
        };
      }
      else {}
    )
    (if globals.isDesktop then ./flatpak.nix else {})

    inputs.home-manager.nixosModules.home-manager
    (
      with inputs; {
        home-manager.useGlobalPkgs = false;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {inherit inputs outputs globals;};
        home-manager.users.${globals.username} = (
          if globals.isNixosWsl then import ./../home-manager/home.nix
          else if globals.isPersonalComputer then import ./../home-manager/home.nix
          else import ./../home-manager/home.nix
        );
      }
    )
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
