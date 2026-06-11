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
    # Process
    pstree
    libcgroup
  ];

  # ==== Process programs ====
  programs.htop.enable = true;
}
