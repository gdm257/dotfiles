{
  inputs,
  outputs,
  globals,
  lib,
  config,
  pkgs,
  ...
}: {
  # Require flatpak
  services.flatpak.packages = [
    # "com.heroicgameslauncher.hgl"
    # "net.davidotek.pupgui2"
    # "com.github.Matoking.protontricks"
    # "com.vysp3r.ProtonPlus"
    "ru.linux_gaming.PortProton"
    # "net.lutris.Lutris"
    "io.github.fastrizwaan.WineZGUI"
    # "com.usebottles.bottles"
    # "com.github.mtkennerly.ludusavi"
    "com.steamgriddb.steam-rom-manager"
    "net.retrodeck.retrodeck"

    # Utilities
    "com.github.tchx84.Flatseal"
    "org.x.Warpinator"
    "com.valvesoftware.SteamLink"
  ];

  home.packages = with pkgs; [
    # Streamming
    wiliwili

    chiaki-ng
    parsec-bin
    moonlight-qt
    sunshine
    todesk
    rustdesk
    ludusavi

    # Emulator Frontend
    retroarch
    emulationstation-de

    # Emulators
    protonplus
    protonup-qt
    proton-caller
    protontricks
    bottles

    # Launcher
    pegasus-frontend
    gamehub
    steamtinkerlaunch
    thcrap-steam-proton-wrapper
    lutris
    heroic

    # Games
    taisei
  ];
}
