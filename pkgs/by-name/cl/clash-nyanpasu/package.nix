{
  lib,
  stdenv,
  sources,
  source ? sources.clash-nyanpasu,
  fetchurl,
  rustPlatform,

  cargo-tauri,
  pkg-config,
  fetchPnpmDeps,
  nodejs_22,
  pnpm,
  pnpmConfigHook,
  wrapGAppsHook4,
  dart-sass,
  jq,
  moreutils,
  brotli,

  nodejsCustom ? nodejs_22,
  pnpmCustom ? pnpm.override { nodejs = nodejs_22; },

  glib-networking,
  glib,
  webkitgtk_4_1,
  libayatana-appindicator,

  # sidecars
  maxmind-geolite2,
  mihomo,
  v2ray-rules-dat,
  nyanpasu-service,
}:
rustPlatform.buildRustPackage (
  finalAttrs:
  let
    inlangPluginMessageFormat = fetchurl {
      name = "plugin-message-format";
      url = "https://cdn.jsdelivr.net/npm/@inlang/plugin-message-format@4/dist/index.js";
      sha256 = "1ivcw81qf70j6wr8d59waa53qm4r6lkwafwn8ld3x623bfyv0c74";
    };

    inlangPluginMFunctionMatcher = fetchurl {
      name = "plugin-m-function-matcher";
      url = "https://cdn.jsdelivr.net/npm/@inlang/plugin-m-function-matcher@2/dist/index.js";
      sha256 = "02ww97ipnlaiq2cpg2xkx8mgnqvf165kdrdgv6zmcfvr0mijz1l5";
    };

    dedent = fetchurl {
      name = "dedent";
      url = "https://fastly.jsdelivr.net/npm/dedent@1.7.0/+esm";
      sha256 = "9f35a6c7ad8715dcabfbdef3dce004cabfc69c2122514bfedb49e92d806c5f81";
    };

    yaml = fetchurl {
      name = "yaml";
      url = "https://fastly.jsdelivr.net/npm/yaml@2.8.1/+esm";
      sha256 = "3105bd033ef3ec02aae6ec350b9cd8ab0c95f799b1492d91fbced69e783578df";
    };

    esToolkit = fetchurl {
      name = "es-toolkit";
      url = "https://fastly.jsdelivr.net/npm/es-toolkit@1.39.10/+esm";
      sha256 = "423e3a9e64d5274c5548e31f7780d85aca76a90602316f122911983f5bd96be3";
    };

    jsBase64 = fetchurl {
      name = "js-base64";
      url = "https://fastly.jsdelivr.net/npm/js-base64@3.7.8/+esm";
      sha256 = "afa632856f8f9196d5e8e00f406c819dc456475a99841bd748937c0476c92615";
    };
  in
  {
    inherit (source) pname version src;

    patches = [
      # `fetchFromGitHub` doesn't clone via git and thus installing would otherwise fail.
      ./git-info.patch
    ];

    # The `packageManager` attribute matches the version _exactly_, which makes
    # the build fail if it doesn't match exactly.
    postPatch = ''
      substituteInPlace package.json \
        --replace-fail '"packageManager": "pnpm@10.26.2"' '"packageManager": "pnpm"'

      substituteInPlace frontend/nyanpasu/project.inlang/settings.json \
        --replace-fail "https://cdn.jsdelivr.net/npm/@inlang/plugin-message-format@4/dist/index.js" "${inlangPluginMessageFormat}" \
        --replace-fail "https://cdn.jsdelivr.net/npm/@inlang/plugin-m-function-matcher@2/dist/index.js" "${inlangPluginMFunctionMatcher}"

      # disable updater
      jq '.plugins.updater.endpoints = [ ] | .bundle.createUpdaterArtifacts = false' \
        backend/tauri/tauri.conf.json | sponge backend/tauri/tauri.conf.json

      mkdir -p backend/tauri/resources
      ln -sf ${v2ray-rules-dat}/share/v2ray/geoip.dat backend/tauri/resources/geoip.dat
      ln -sf ${v2ray-rules-dat}/share/v2ray/geosite.dat backend/tauri/resources/geosite.dat
      ln -sf ${maxmind-geolite2}/share/geolite2/country.mmdb backend/tauri/resources/Country.mmdb
      jq '.bundle.externalBin = [ ]' backend/tauri/tauri.conf.json | sponge backend/tauri/tauri.conf.json

      # Fix boa_utils downloading assets during build
      mkdir -p backend/boa_utils/assets
      cp ${dedent} backend/boa_utils/assets/dedent.js
      cp ${yaml} backend/boa_utils/assets/yaml.js
      cp ${esToolkit} backend/boa_utils/assets/es-toolkit.js
      cp ${jsBase64} backend/boa_utils/assets/js-base64.js

      # The macro expects brotli compressed files
      brotli backend/boa_utils/assets/*.js

      substituteInPlace backend/boa_utils/src/module/builtin.rs \
        --replace-fail 'include_url_bytes_with_brotli!("https://fastly.jsdelivr.net/npm/dedent@1.7.0/+esm")' 'include_bytes!("../../assets/dedent.js.br")' \
        --replace-fail 'include_url_bytes_with_brotli!("https://fastly.jsdelivr.net/npm/yaml@2.8.1/+esm")' 'include_bytes!("../../assets/yaml.js.br")' \
        --replace-fail 'include_url_bytes_with_brotli!("https://fastly.jsdelivr.net/npm/es-toolkit@1.39.10/+esm")' 'include_bytes!("../../assets/es-toolkit.js.br")' \
        --replace-fail 'include_url_bytes_with_brotli!("https://fastly.jsdelivr.net/npm/js-base64@3.7.8/+esm")' 'include_bytes!("../../assets/js-base64.js.br")'
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      substituteInPlace $cargoDepsCopy/libappindicator-sys-*/src/lib.rs \
        --replace-fail "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"
    '';

    nativeBuildInputs = [
      cargo-tauri.hook
      dart-sass
      jq
      moreutils
      brotli
      nodejsCustom
      pkg-config
      pnpmConfigHook
      pnpmCustom
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

    # force sass-embedded to use our own sass from PATH instead of the bundled one
    preBuild = ''
      substituteInPlace node_modules/.pnpm/node_modules/sass-embedded/dist/lib/src/compiler-path.js \
        --replace-fail 'compilerCommand = (() => {' 'compilerCommand = (() => { return ["dart-sass"];'
    '';

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      glib
      glib-networking
      webkitgtk_4_1
      libayatana-appindicator
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      pnpm = pnpmCustom;
      fetcherVersion = 3;
      hash = "sha256-xG6gqtccU2mZOyifGm4Gjn3ACHM9EWBX9d9nzhCLadI=";
    };

    cargoRoot = "backend";
    buildAndTestSubdir = finalAttrs.cargoRoot;
    cargoDeps = rustPlatform.importCargoLock source.cargoLock."backend/Cargo.lock";

    env = {
      COMMIT_HASH = finalAttrs.src.rev;
      COMMIT_AUTHOR = finalAttrs.src.owner;
      COMMIT_DATE = "${source.date}T00:00:00Z";
      RUSTC_BOOTSTRAP = 1; # required by include-compress-bytes-0.1.0
    };

    # postInstall = ''
    #   install -Dm444 clash-nyanpasu.desktop -t $out/share/applications
    #   cp -r usr/share/icons $out/share
    # '';
    checkFlags = [
      "--skip=module::http::test_http_module_loader"
      "--skip=enhance::script::js::test::test_process_honey_with_fetch"
    ];

    postInstall = ''
      ln -sf ${lib.getExe mihomo} $out/bin/mihomo
      ln -sf ${lib.getExe nyanpasu-service} $out/bin/nyanpasu-service
    '';

    meta = {
      description = "Clash GUI based on tauri";
      homepage = "https://github.com/LibNyanpasu/clash-nyanpasu";
      license = lib.licenses.gpl3Plus;
      maintainers = with lib.maintainers; [ moraxyc ];
      mainProgram = "clash-nyanpasu";
    };
  }
)
