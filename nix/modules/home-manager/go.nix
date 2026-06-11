{
  lib,
  config,
  pkgs,
  ...
}: {
  programs.go = {
    enable = true;
  };
  home.packages = with pkgs; [
    gcc
    golangci-lint
    goreleaser
    protoc-gen-go
  ];
}
