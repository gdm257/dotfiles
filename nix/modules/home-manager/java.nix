{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # sdk
    zulu

    # sdk manager
    jbang

    # package manager
    maven

    # android
    android-tools
    apk-tool
  ];

  # package manager
  programs.gradle.enable = true;
}
