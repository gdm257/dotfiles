{
  lib,
  config,
  pkgs,
  ...
}: {
  home.shellAliases = {
    "conda" = "micromamba";
  };
  home.packages = with pkgs; [
    # package manager
    uv

    # global env
    python3Minimal

    # venv
    micromamba

    # linter/formatter
    ruff
  ];
}
