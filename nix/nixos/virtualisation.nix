{
  globals,
  lib,
  config,
  pkgs,
  ...
}: {
  virtualisation.docker = {
    enable = true;
    listenOptions = [ "/run/docker.sock" ];
    daemon.settings = {
      hosts = [ "tcp://0.0.0.0:2375" ];
    };
  };

  virtualisation.containerd = {
    enable = false; # disable if k3s is enabled
  };

  virtualisation.cri-o = {
    enable = false;
  };

  services.k3s = {
    enable = false;
    package = pkgs.k3s_1_28; # override if you want to specify k3s version
    role = "server";
    clusterInit = true;
    # token = "random-secret";
    # serverAddr = "https://localhost:6443"; # if IP detection fails
    extraFlags = [
      # "--debug"
      "-v=0" "--log=/var/log/k3s.log"
      "--secrets-encryption"
      "--disable=traefik,servicelb"
      "--flannel-backend=none" "--disable-network-policy"
      "--https-listen-port=6443"
      "--etcd-snapshot-retention=12"
      "--data-dir=/var/lib/rancher/k3s"
      # "--write-kubeconfig=${globals.home}/.kube/config"
      # "--write-kubeconfig-mode=644"
    ];
  };
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    # 8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];
  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
