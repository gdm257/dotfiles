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
    # Network
    bandwhich
    doggo
    gping
    caddy
    localias
  ];
}
