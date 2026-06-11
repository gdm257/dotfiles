{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # sdk
    nodejs_22

    # sdk manager
    volta
  ];
}
