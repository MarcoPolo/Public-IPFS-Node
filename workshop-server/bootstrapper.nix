{ buildGo118Module, lib, fetchFromGitHub }:
buildGo118Module rec {
  src = ./.;

  pname = "bootstrapper";
  version = "0.0.1";
  # subPackages = [ "cmd/ipfs" ];
  checkPhase = "";


  vendorSha256 = "sha256-b6IjHasCuhCHEujOVCHBPHcVv4ReregpgoiQN9iuGZ8=";
  # vendorSha256 = lib.fakeSha256;

  meta = with lib; {
    description = "";
    homepage = "https://github.com/ipfs/go-ipfs";
    license = licenses.mit;
    maintainers = with maintainers; [ "marcopolo" ];
    platforms = platforms.linux ++ platforms.darwin;
  };

  postInstall = ''
    mv $out/bin/m $out/bin/bootstrapper
  '';
}

