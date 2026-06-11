{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    shfmt
    shellcheck
  ];
}
