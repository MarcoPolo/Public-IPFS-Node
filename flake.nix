{
  description = "A very basic flake";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-22.05";
  inputs.deploy-rs = {
    url = "github:serokell/deploy-rs";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = { self, nixpkgs, flake-utils, deploy-rs }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { system = system; };
          terraformVersion = pkgs.runCommand "tf-version" { } ''
            mkdir $out
            ${pkgs.terraform}/bin/terraform version > $out/version
          '';
          jq = "${pkgs.jq}/bin/jq";
          update-terraform-output = pkgs.writeScriptBin "update-terraform-output"
            ''
              tmpfile=$(mktemp)

              # Remove any sensitive output
              ${pkgs.terraform}/bin/terraform output -json |  ${jq} 'with_entries( select(.value | .sensitive == false ) )' > "$tmpfile"
              # Is there an update?
              if ! cmp terraform-output.json "$tmpfile" >/dev/null 2>&1
              then
                mv $tmpfile terraform-output.json
              fi

              cat terraform-output.json
            '';
        in
        {
          packages.hello = pkgs.hello;
          packages.ipfs = pkgs.callPackage (import ./ipfs.nix) { };
          defaultPackage = self.packages.${system}.hello;
          devShell = pkgs.mkShell {
            buildInputs = [
              pkgs.fail2ban
              pkgs.terraform
              pkgs.awscli
              update-terraform-output
              deploy-rs.defaultPackage.${system}
            ];
            FOO = terraformVersion;
          };
        })) // {
      deploy.nodes = {
        ipfs = {
          hostname = (builtins.fromJSON (builtins.readFile ./terraform-output.json)).ipfs-node-ip.value;
          profiles.system = {
            user = "root";
            sshUser = "marco";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.ipfs;
          };
        };
      };

      nixosConfigurations = {
        ipfs = nixpkgs.lib.nixosSystem
          (
            let system = "x86_64-linux";
            in
            {
              inherit system;
              modules = [
                ({ pkgs, ... }: {
                  environment.systemPackages =
                    with pkgs;
                    [ go_1_18 vim git tmux curl htop ];
                })
                ({ modulesPath, ... }: {
                  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
                  ec2.hvm = true;
                  system.stateVersion = "22.05";
                })

                ({ pkgs, modulesPath, ... }:
                  {

                    networking.hostName = "ipfsNode";
                    networking.firewall.enable = false;

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
                      openssh.authorizedKeys.keys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJg919RUJA487kzkOQ5cwCFtGY8BGJ/Ehpjh20+JcRB marco@mukta.lan"
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUY0mjDe29MhiPIZhtLiOi8ORRctayc1xPbfYJ6WT9e marco@dex"
                      ];
                    };
                  })

                ({ config, pkgs, ... }:
                  {
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

                    security.acme.acceptTerms = true;
                    security.acme.defaults.email = "git@marcopolo.io";

                    services.nginx.virtualHosts.${config.services.grafana.domain} = {
                      addSSL = true;
                      enableACME = true;
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

                    # services.ipfs = {
                    #   enable = true;
                    #   package = self.packages.${system}.ipfs // { repoVersion = "13"; };
                    # };
                    environment.systemPackages = [
                      self.packages.${system}.ipfs
                    ];

                    networking.firewall.allowedTCPPorts = [ 80 443 ];

                  })
              ];
            }
          );
      };
    };
}
