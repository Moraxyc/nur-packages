{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "flap-alerted";
  version = "3.14.1";

  src = fetchFromGitHub {
    owner = "Kioubit";
    repo = "FlapAlerted";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OLTqxYPNfKg2S2BH5CrWzgdpFOPA+cDC0CLMIwGUHFg=";
  };

  vendorHash = null;

  ldflags = [
    "-s"
    "-X main.Version=${finalAttrs.version}"
  ];

  meta = {
    description = "BGP Update based flap detection";
    homepage = "https://github.com/Kioubit/FlapAlerted/";
    # no license
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ moraxyc ];
    mainProgram = "FlapAlerted";
  };
})
