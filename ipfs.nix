{ buildGo117Module, lib, fetchFromGitHub }:
buildGo117Module rec {
  src = fetchFromGitHub {
    owner = "ipfs";
    repo = "go-ipfs";
    rev = "rcgmr-auto-scale";
    sha256 = "sha256-HWu61bUyNAGzbIeOqJScH1XSAtRfXAoLe4ZWj0ykgnM=";
    # sha256 = lib.fakeSha256;
  };

  pname = "kubo";
  version = "0.0.1";
  subPackages = [ "cmd/ipfs" ];
  checkPhase = "";


  vendorSha256 = "sha256-Qpvug3MF9zj+4HFNi1MeotvCy8Ff6RABxk1NVdf0gSk=";
  # vendorSha256 = lib.fakeSha256;

  meta = with lib; {
    description = "";
    homepage = "https://github.com/ipfs/go-ipfs";
    license = licenses.mit;
    maintainers = with maintainers; [ "marcopolo" ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}

