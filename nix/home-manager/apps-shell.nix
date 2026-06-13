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
    uutils-coreutils-noprefix
    coreutils
    util-linux
    findutils

    firejail
    opkssh
    openssh
    powershell
    wsl-open
    xdg-utils
  ];
}
