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
    # DevOps
    bit
    gitui
    elfutils
    elfkickers
    elf-info
    devpod
  ];

  # ==== DevOps programs ====
  programs.git.enable = true;
  programs.distrobox = {
    enable = true;
  };
}
