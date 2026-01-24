{
  lib,
  rustPlatform,
  sources,
  source ? sources.nyanpasu-service,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  inherit (source) pname version src;

  patches = [ ./git-info.patch ];

  env = {
    COMMIT_HASH = finalAttrs.src.rev;
    COMMIT_AUTHOR = finalAttrs.src.owner;
    COMMIT_DATE = "${source.date}T00:00:00Z";
    BUILD_DATE = "${source.date}T00:00:00Z";
    RUSTC_BOOTSTRAP = 1;
  };

  cargoDeps = rustPlatform.importCargoLock source.cargoLock."Cargo.lock";

  meta = {
    description = "Cross platform privileged service for Nyanpasu";
    homepage = "https://github.com/libnyanpasu/nyanpasu-service";
    changelog = "https://github.com/libnyanpasu/nyanpasu-service/blob/${finalAttrs.src.rev}/CHANGELOGS.md";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ moraxyc ];
    mainProgram = "nyanpasu-service";
  };
})
