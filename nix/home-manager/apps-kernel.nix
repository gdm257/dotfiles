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
    # Kernel
    fastfetch
  ];
}
