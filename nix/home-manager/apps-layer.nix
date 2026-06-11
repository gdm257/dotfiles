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
    # Layer
    podman passt shadow # rootless
    cntr
    containerlab
    ctop
    lazydocker
    kompose
    kubernetes-helm
    helmfile
    k3sup
    k3d
    k9s
    krew
    kubectx
    velero
    # libguestfs # too large
  ];
}
