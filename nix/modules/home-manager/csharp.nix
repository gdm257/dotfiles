{
  lib,
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    dotnet-sdk
    nuget
    ilspy
  ];
}
