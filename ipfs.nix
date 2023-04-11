{ buildGo119Module, lib, fetchFromGitHub }:
buildGo119Module rec {
  src = fetchFromGitHub {
    owner = "marcopolo";
    repo = "go-ipfs";
    rev = "marco/http-over-webtransport";
    sha256 = "sha256-+gbth8XWxHByVn6upqHd4XQdHMFsVOrUXn/ZevKj7UY=";
    # sha256 = lib.fakeSha256;
  };

  pname = "kubo";
  version = "0.0.1";
  subPackages = [ "cmd/ipfs" ];
  checkPhase = "";


  vendorSha256 = "sha256-GBCoufjnApmJeyrgEgI/0VPxj879UvlVsFl2pUHz/7A=";
  # vendorSha256 = lib.fakeSha256;

  meta = with lib; {
    description = "";
    homepage = "https://github.com/ipfs/go-ipfs";
    license = licenses.mit;
    maintainers = with maintainers; [ "marcopolo" ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}

