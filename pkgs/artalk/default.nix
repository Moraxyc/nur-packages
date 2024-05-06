{
  lib,
  buildGoModule,
  fetchFromGitHub,
  artalk,
  testers,
  nodePackages,
  stdenv,
  stdenvNoCC,
  jq,
  cacert,
  moreutils,
}:
let
  version = "2.8.5";

  src = fetchFromGitHub {
    owner = "ArtalkJS";
    repo = "artalk";
    rev = "v${version}";
    hash = "sha256-pzjSig+vJ5QlpNE71UlC1MJdbvkIdswl+wiKMpjE/CM=";
  };

  frontend = stdenv.mkDerivation (finalAttrs: {
    pname = "artalk-frontend";
    inherit version src;

    pnpmDeps = stdenvNoCC.mkDerivation {
      pname = "${finalAttrs.pname}-pnpm-deps";
      inherit (finalAttrs) src version;

      nativeBuildInputs = [
        nodePackages.pnpm
        jq
        cacert
        moreutils
      ];

      installPhase = ''
        runHook preInstall

        export HOME=$(mktemp -d)

        pnpm config set store-dir $out
        pnpm install --frozen-lockfile

        rm -rf $out/v3/tmp
        for f in $(find $out -name "*.json"); do
          sed -i -E -e 's/"checkedAt":[0-9]+,//g' $f
          jq --sort-keys . $f | sponge $f
        done

        runHook postInstall
      '';

      dontBuild = true;
      dontFixup = true;
      outputHashMode = "recursive";
      outputHash = "sha256-cGMzn5WsGs3pNOSI8uYPNGukMU7QLd7zbrAZ9g/bT+4=";
    };

    nativeBuildInputs = [
      nodePackages.pnpm
      nodePackages.nodejs
    ];

    doCheck = false;

    preBuild = ''
      export HOME=$(mktemp -d)

      pnpm config set store-dir ${finalAttrs.pnpmDeps}
      pnpm install --offline --frozen-lockfile
      patchShebangs node_modules/{*,.*}
    '';

    buildPhase = ''
      runHook preBuild

      pnpm -F artalk build
      pnpm -F @artalk/artalk-sidebar build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      ## dist
      DIST_DIR="$out/dist"
      mkdir -p $DIST_DIR
      cp -r ./ui/artalk/dist/{Artalk.css,Artalk.js} $DIST_DIR
      cp -r ./ui/artalk/dist/{ArtalkLite.css,ArtalkLite.js} $DIST_DIR

      I18N_DIR="''${DIST_DIR}/i18n"
      mkdir -p $I18N_DIR
      cp -r ./ui/artalk/dist/i18n/*.js $I18N_DIR

      ## sidebar
      SIDEBAR_DIR="$out/sidebar"
      mkdir -p $SIDEBAR_DIR
      cp -r ./ui/artalk-sidebar/dist/* $SIDEBAR_DIR

      runHook postInstall
    '';
  });
in
buildGoModule rec {
  inherit src version;
  pname = "artalk";

  CGO_ENABLED = 1;

  vendorHash = "sha256-LI14Xfzd8AiDJq13H471MqocUn3jvkiXSuWeWOaSC40=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/ArtalkJS/Artalk/internal/config.Version=${version}"
    "-X github.com/ArtalkJS/Artalk/internal/config.CommitHash=${version}"
  ];
  prePatch = ''
    cp -r ${frontend}/{sidebar,dist} public/
  '';

  passthru.tests = {
    version = testers.testVersion { package = artalk; };
  };

  meta = with lib; {
    description = "A self-hosted comment system";
    homepage = "https://github.com/ArtalkJS/Artalk";
    license = licenses.mit;
    maintainers = with maintainers; [ moraxyc ];
    mainProgram = "Artalk";
  };
}
