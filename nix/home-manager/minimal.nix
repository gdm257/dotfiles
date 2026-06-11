{
  inputs,
  outputs,
  globals,
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # Shell

    # DevOps
    go-task
    gh

    # Downloader

    # File
    nix-tree

    # Kernel

    # Layer

    # Network
    curl
    wget
    iproute2

    # Process

    # Text
  ];

  # ==== DevOps programs ====
  programs.jujutsu = {
    enable = true;
  };
  programs.uv = {
    enable = true;
  };
  programs.bun = {
    enable = true;
  };

  # ==== File programs ====
  programs.eza = {
    enable = true;
    icons = "never";
    extraOptions = [ "--group-directories-first" ];
  };
  programs.fzf = {
    enable = true;
    # enableBashIntegration = false;
    # enableFishIntegration = false;
    # enableZshIntegration = false;
  };

}
