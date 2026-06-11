{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # User-scoped
  # TODO: fix remote errors
  # services.flatpak.remotes = lib.mkOptionDefault [ # Add a new remote. Keep the default one (flathub)
  #     {
  #       name = "flathub-beta";
  #       url = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
  #     }
  # ];
  services.flatpak.update.auto.enable = false;
  services.flatpak.uninstallUnmanaged = false;
  services.flatpak.packages = [
    # { appId = "org.telegram.desktop"; origin = "flathub"; }
    # "org.telegram.desktop"
  ];
}
