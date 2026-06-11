{
  inputs,
  outputs,
  globals,
  lib,
  config,
  pkgs,
  ...
}: {
  # Run the Proxmox Hypervisor on top of NixOS
  imports = [
    inputs.proxmox-nixos.nixosModules.proxmox-ve
    {
      services.proxmox-ve = {
        enable = true;
        ipAddress = "192.168.0.1";
      };
      nixpkgs.overlays = [
        inputs.proxmox-nixos.overlays.${globals.system}
      ];
    }
  ];
}
