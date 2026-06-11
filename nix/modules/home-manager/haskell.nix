{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    haskell.compiler.ghc94
    haskellPackages.stack
  ];
}
