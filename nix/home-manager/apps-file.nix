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
    # File
    age
    duf
    dust
    fd
    file
    lvm2_vdo
  ];
}
