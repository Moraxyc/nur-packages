{
  buildNpmPackage,
  fetchPnpmDeps,
  installDistHook,
  nodejs,
  pnpm,
  pnpmConfigHook,

  pname,
  src,
  version,
}:

buildNpmPackage (finalAttrs: {
  pname = "${pname}-web";
  inherit version src;

  npmDeps = null;
  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-T6BKQSymbbW5V/aAXjMMqz/A/sq5oCB1Ztb8t+AaYho=";
    fetcherVersion = 3;
  };

  npmConfigHook = pnpmConfigHook;

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm
  ];

  installDistDir = "apps/web/dist";
  npmInstallHook = installDistHook;
})
