{
  globals,
  lib,
  config,
  pkgs,
  ...
}: {
  # TODO: Set your hostname
  networking.hostName = globals.hostname;
}
