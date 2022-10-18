data "aws_caller_identity" "current" {}

locals {
  prefix     = "marco"
  account_id = data.aws_caller_identity.current.account_id
}

module "nixos_image" {
  source  = "./aws_image_nixos"
  release = "22.05"
}

resource "aws_key_pair" "marco_nix_key" {
  key_name   = "marco_ipfs_deploy_key"
  public_key = file(var.deploy_pub_key_path)
}

resource "aws_security_group" "marco-ipfs-sg" {
  name = "nix_sg"
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 3000
    to_port   = 3003
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 2112
    to_port   = 2112
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 9091
    to_port   = 9091
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 4001
    to_port   = 4001
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 4001
    to_port   = 5001
    protocol  = "udp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 7000
    to_port   = 8000
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ipfs-node" {
  ami           = module.nixos_image.ami
  instance_type = "t2.medium"
  key_name      = aws_key_pair.marco_nix_key.key_name
  root_block_device {
    volume_size = 256
  }
  security_groups = [aws_security_group.marco-ipfs-sg.name]
  user_data       = <<-USEREOF
  {pkgs, modulesPath, ...}:
  {
    imports = [ "$${modulesPath}/virtualisation/amazon-image.nix" ];
    ec2.hvm = true;

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
  }
  USEREOF
}

output "ipfs-node-ip" {
  value = aws_instance.ipfs-node.public_ip
}
