{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    xmake
    llvmPackages.clang
    doxygen
    qtcreator
  ];
}
