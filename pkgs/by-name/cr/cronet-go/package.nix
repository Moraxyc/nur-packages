{
  lib,
  stdenvNoCC,
  buildPackages,
  apple-sdk_15,
  darwin,
  ninja,
  python3,
  replaceVars,
  symlinkJoin,
  xcbuild,

  sources,
  source ? sources.cronet-go,
}:
let
  llvmCcAndBintools = symlinkJoin {
    name = "llvmCcAndBintools";
    paths = with buildPackages.llvmPackages; [
      llvm
      stdenv.cc
    ];
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit (source) pname version src;

  postPatch = ''
    substituteInPlace naiveproxy/src/build/config/compiler/BUILD.gn \
      --replace-fail 'cflags += [ "-fno-lifetime-dse" ]' '# cflags += [ "-fno-lifetime-dse" ]' \
      --replace-fail '"-fsanitize-ignore-for-ubsan-feature=array-bounds"' '# "-fsanitize-ignore-for-ubsan-feature=array-bounds"' \
      --replace-fail '"-Wno-unsafe-buffer-usage-in-static-sized-array"' '# "-Wno-unsafe-buffer-usage-in-static-sized-array"'
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    patchShebangs naiveproxy/src/build/toolchain/apple/linker_driver.py

    substituteInPlace naiveproxy/src/build/config/mac/BUILD.gn \
      --replace-fail 'common_mac_flags = []' 'common_mac_flags = [ "-I${lib.getInclude darwin.libresolv}/include" ]'
  '';

  nativeBuildInputs = [
    buildPackages.llvmPackages.bintools
    ninja
    python3
  ]
  ++ lib.optional stdenvNoCC.hostPlatform.isDarwin xcbuild;

  buildInputs = lib.optional stdenvNoCC.hostPlatform.isDarwin apple-sdk_15;

  buildPhase = ''
    runHook preBuild

    ${lib.getExe finalAttrs.passthru.build-naive} build
    ${lib.getExe finalAttrs.passthru.build-naive} package --local
    ${lib.getExe finalAttrs.passthru.build-naive} package

    runHook postBuild
  '';

  outputs = [
    "out"
    "dev"
    "static"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    install -Dm755 lib/*/libcronet${stdenvNoCC.hostPlatform.extensions.sharedLibrary} \
      $out/lib/libcronet${stdenvNoCC.hostPlatform.extensions.sharedLibrary}
  ''
  + ''
    install -Dm644 lib/*/libcronet.a $static/lib/libcronet.a

    mkdir -p $dev/include/cronet-go $dev/share/cronet-go/go
    install -Dm644 include/*.h -t $dev/include/cronet-go
    install -Dm644 include_cgo.go lib/*/*.go lib/*/go.mod -t $dev/share/cronet-go/go

    runHook postInstall
  '';

  passthru = {
    build-naive = buildPackages.buildGoModule {
      pname = finalAttrs.pname + "-build-naive";
      inherit (finalAttrs) version src;
      # nix-update auto -s build-naive
      vendorHash = "sha256-tVIKTznnducPfATK151TpC3UV2U852TyclBTSgh/H6U=";
      patches = [
        (replaceVars ./build-naive.patch {
          gn = lib.getExe buildPackages.gn;
          clang_base_path = llvmCcAndBintools;
        })
      ];
      subPackages = [ "cmd/build-naive" ];
      meta.mainProgram = "build-naive";
    };
    _ignoreOverride = true;
  };

  meta = {
    description = "Go bindings for naiveproxy";
    homepage = "https://github.com/SagerNet/cronet-go";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ moraxyc ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
