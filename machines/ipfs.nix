{ config, pkgs, modulesPath, ... }: {
  # services.ipfs = {
  #   enable = true;
  #   package = self.packages.${system}.ipfs // { repoVersion = "14"; };
  # };

  # Setup systemd ipfs
  systemd.services.ipfs-daemon = {
    description = "ipfs-daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Environment = ''GOLOG_LOG_LEVEL="canonical-log=info"'';
      ExecStart = "${pkgs.ipfs}/bin/ipfs daemon";
      Restart = "always";
      RestartSec = "1min";
      User = "ipfsRunner";
    };
  };

  # Setup bootstrap server deamon
  systemd.services.bootstrap-daemon = {
    description = "bootstrap-daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bootstrapper}/bin/bootstrapper";
      Restart = "always";
      RestartSec = "1min";
      User = "ipfsRunner";
    };
  };

  environment.systemPackages = [
    pkgs.ipfs
    pkgs.getent
    pkgs.tmux
  ] ++ (

    # Some niceties
    with pkgs;
    [ go_1_18 vim git tmux curl htop ]
  );

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPortRanges = [{ from = 1; to = 10000; }];
    allowedUDPPortRanges = [{ from = 1; to = 10000; }];
  };

  # Configure fail2ban
  environment.etc."fail2ban/filter.d/go-libp2p-peer-status.conf".source = ../fail2ban/filter.d/go-libp2p-peer-status.conf;
  services.fail2ban = {
    enable = true;
    jails = {
      # go-libp2p specific jail
      go-libp2p-weird-behavior-iptables = ''
        # Block an IP address if it fails a handshake or reconnects more than
        # 50 times a second over the course of 3 minutes. Since
        # we sample at 1% this means we block if we see more
        # than 90 failed handshakes over 3 minutes. (50 logs/s * 1% = 1 log every 
        # 2 seconds. for 60 * 3 seconds = 90 reqs in 3 minutes.)
        enabled  = true
        filter   = go-libp2p-peer-status
        action   = iptables-allports[name=go-libp2p-fail2ban]
        backend = systemd[journalflags=1]
        journalmatch = _SYSTEMD_UNIT=ipfs-daemon.service
        findtime = 180 # 3 minutes
        bantime  = 600 # 10 minutes
        maxretry = 90
      '';

    };

  };

  # Config for running in an EC2 instance.
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  ec2.hvm = true;
  system.stateVersion = "22.05";

  # General NixOS setup. enable flakes, users, ssh keys

  networking.hostName = "ipfsNode";
  # networking.firewall.enable = false;

  # Enable Flakes
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    trustedUsers = [ "root" "marco" ];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.marco = {
    isNormalUser = true;
    shell = pkgs.zsh;
    uid = 1005;
    createHome = true;
    extraGroups = [ "wheel" "ipfs" ];
    group = "ipfsRunner";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJg919RUJA487kzkOQ5cwCFtGY8BGJ/Ehpjh20+JcRB marco@mukta.lan"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUY0mjDe29MhiPIZhtLiOi8ORRctayc1xPbfYJ6WT9e marco@dex"
    ];
  };

  users.users.ipfsRunner = {
    isSystemUser = true;
    shell = pkgs.zsh;
    uid = 1006;
    createHome = false;
    extraGroups = [ "ipfs" ];
    group = "ipfsRunner";
    openssh.authorizedKeys.keys = [ ];
  };
  users.groups.ipfsRunner = { };

  # Obs
  # For grafana obs
  services.grafana = {
    enable = true;
    port = 2342;
    domain = "ipfs.marcopolo.io";
    addr = "127.0.0.1";
    dataDir = "/var/lib/grafana";
    auth.anonymous.enable = true;

    provision = {
      enable = true;
      datasources = [{
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:9001";
        isDefault = true;
      }];
    };
  };

  # for obs
  services.prometheus = {
    enable = true;
    port = 9001;
    globalConfig.scrape_interval = "15s";
    # To support read-load-generators emitting metrics
    pushgateway.enable = true;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "local-node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
      {
        job_name = "public-ipfs";
        metrics_path = "/debug/metrics/prometheus";
        static_configs = [
          {
            targets = [ "127.0.0.1:5001" ];
          }
        ];
      }
    ];

  };

  # Setup acme + ssl
  # security.acme.acceptTerms = true;
  # security.acme.defaults.email = "git@marcopolo.io";

  services.nginx.virtualHosts.${config.services.grafana.domain} = {
    # addSSL = true;
    # enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
      proxyWebsockets = true;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
}
