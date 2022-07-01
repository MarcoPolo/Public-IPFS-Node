{ buildGo117Module, lib, fetchFromGitHub }:
buildGo117Module rec {
  src = fetchFromGitHub {
    owner = "marcopolo";
    repo = "go-ipfs";
    rev = "marco/go-libp2p-21-rc";
    sha256 = "sha256-zCGD7pRLRDSo4RMOwELKl8xnkuzCyG0MOSvH8c3y1SQ=";
    # vendorSha256 = pkgs.lib.fakeSha256;    
  };

  pname = "kubo";
  version = "0.0.1";
  subPackages = [ "cmd/ipfs" ];
  checkPhase = "";


  vendorSha256 = "sha256-5vBNSn9ovvB6N4ywZrG3dwV250Pa+zBCdlL//4ZU6ec=";
  # vendorSha256 = lib.fakeSha256;

  meta = with lib; {
    description = "";
    homepage = "https://github.com/ipfs/go-ipfs";
    license = licenses.mit;
    maintainers = with maintainers; [ "marcopolo" ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}

