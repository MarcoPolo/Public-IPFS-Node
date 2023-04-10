{
  description = "A very basic flake";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
  inputs.deploy-rs = {
    url = "github:serokell/deploy-rs";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.colmena =
    {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

  outputs = { self, nixpkgs, flake-utils, deploy-rs, colmena }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            system = system;
          };
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
          packages.bootstrapper = pkgs.callPackage (import ./workshop-server/bootstrapper.nix) { };
          defaultPackage = self.packages.${system}.hello;
          devShell = pkgs.mkShell {
            buildInputs = [
              pkgs.fail2ban
              pkgs.terraform
              pkgs.awscli
              update-terraform-output
              deploy-rs.defaultPackage.${system}

              # colmena.defaultPackage.${system}
              pkgs.colmena

              # go-libp2p
              pkgs.go_1_18
            ];
            FOO = terraformVersion;
          };
        })) // {
      deploy.nodes = {
        ipfs = {
          profiles.system = {
            user = "root";
            sshUser = "marco";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.ipfs;
          };
        };
      };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              (final: prev: {
                ipfs = self.packages.${"x86_64-linux"}.ipfs;
                bootstrapper = self.packages.${"x86_64-linux"}.bootstrapper;
              })
            ];
          };
        };

        host-ipfs = {
          deployment = {
            targetHost = (builtins.fromJSON (builtins.readFile ./terraform-output.json)).ipfs-node-ip.value;
            targetUser = "root";
          };
          boot.isContainer = true;
          time.timeZone = "America/Los_Angeles";
          imports = [ ./machines/ipfs.nix ];
        };
      };

      nixosConfigurations = {
        ipfs = nixpkgs.lib.nixosSystem
          (
            let system = "x86_64-linux";
            in
            {
              inherit system;
              modules = [ ./machines/ipfs.nix ];
            }
          );
      };
    };
}
