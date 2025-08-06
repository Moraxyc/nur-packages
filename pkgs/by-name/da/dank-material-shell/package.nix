{
  lib,
  stdenvNoCC,
  nix-update-script,
  sources,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dank-material-shell";
  version = lib.removePrefix "v" sources.${finalAttrs.pname}.version;

  inherit (sources.${finalAttrs.pname}) src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/etc/xdg/quickshell
    cp -r . $out/etc/xdg/quickshell/DankMaterialShell

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Quickshell for Niri";
    homepage = "https://github.com/bbedward/DankMaterialShell";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ moraxyc ];
  };
})
