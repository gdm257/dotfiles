# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  globals,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # Or modules your own flake exports (from modules/home-manager):
    outputs.homeManagerModules.vim
    # outputs.homeManagerModules.nix

    # You can also split up your configuration and import pieces of it here:
    ./editorconfig.nix
    ./shell.nix

    ./minimal.nix

    (if globals.isDesktop then inputs.nix-flatpak.homeManagerModules.nix-flatpak else {})
    (if globals.isDesktop then ./flatpak.nix else {})
    (if globals.isDesktop && globals.isSteamDeck then ./steamdeck.nix else {})
    (if globals.enableFile then ./apps-file.nix else {})
    (if globals.enableText then ./apps-text.nix else {})
    (if globals.enablePicture then ./apps-picture.nix else {})
    (if globals.enableAudio then ./apps-audio.nix else {})
    (if globals.enableVideo then ./apps-video.nix else {})
    (if globals.enableProcess then ./apps-process.nix else {})
    (if globals.enableKernel then ./apps-kernel.nix else {})
    (if globals.enableDownloader then ./apps-downloader.nix else {})
    (if globals.enableNetwork then ./apps-network.nix else {})
    (if globals.enableLayer then ./apps-layer.nix else {})
    (if globals.enableShell then ./apps-shell.nix else {})
    (if globals.enableDevops then ./apps-devops.nix else {})
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  home = {
    username = globals.username;
    homeDirectory = globals.home;
  };

  # Enable home-manager
  home.packages = [ pkgs.home-manager ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  # https://github.com/nix-community/home-manager/issues/5794
  home.stateVersion = "24.11";
}
