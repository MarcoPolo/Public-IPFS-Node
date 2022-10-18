{ buildGo118Module, lib, fetchFromGitHub }:
buildGo118Module rec {
  src = fetchFromGitHub {
    owner = "ipfs";
    repo = "go-ipfs";
    rev = "bf8274f6e2afb28a624b75859991cb164cb367ff";
    sha256 = "sha256-W+JhuFAts3hc+5m027fqiAOaIpQeUhhSpizBz1vFMnY=";
    # sha256 = lib.fakeSha256;
  };

  pname = "kubo";
  version = "0.0.1";
  subPackages = [ "cmd/ipfs" ];
  checkPhase = "";


  vendorSha256 = "sha256-WLACFY+mqyOA2VY0SAwvKCMsk8rrTY8u4CmnzVUIMGk=";
  # vendorSha256 = lib.fakeSha256;

  meta = with lib; {
    description = "";
    homepage = "https://github.com/ipfs/go-ipfs";
    license = licenses.mit;
    maintainers = with maintainers; [ "marcopolo" ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}

