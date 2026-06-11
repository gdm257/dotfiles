{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # System-scoped
  services.flatpak.enable = true;
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
    # { appId = "com.brave.Browser"; origin = "flathub"; }
    # "com.brave.Browser"
  ];
}
