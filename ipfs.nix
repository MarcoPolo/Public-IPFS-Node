{ buildGo119Module, lib, fetchFromGitHub }:
buildGo119Module rec {
  src = fetchFromGitHub {
    owner = "marcopolo";
    repo = "go-ipfs";
    rev = "marco/http-over-webtransport";
    sha256 = "sha256-u/cvI29ssKToZys0UqNcuvneqZ/2Lo9Ydht4D7eeTtc=";
    # sha256 = lib.fakeSha256;
  };

  pname = "kubo";
  version = "0.0.1";
  subPackages = [ "cmd/ipfs" ];
  checkPhase = "";


  vendorSha256 = "sha256-ET4yKTw2A/N0GlMB8tRfbcDkNWEeOoxArPCGdKevmsw=";
  # vendorSha256 = lib.fakeSha256;

  meta = with lib; {
    description = "";
    homepage = "https://github.com/ipfs/go-ipfs";
    license = licenses.mit;
    maintainers = with maintainers; [ "marcopolo" ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}

