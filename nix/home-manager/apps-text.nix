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
    # Text
    jq
    ripgrep
    sad
    yq
  ];
}
