{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    upx
    cutter
  ];
}
