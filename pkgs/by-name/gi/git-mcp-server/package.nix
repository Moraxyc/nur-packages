{
  lib,
  buildNpmPackage,
  bunConfigHook,
  fetchBunDeps,
  bun,

  sources,
  source ? sources.git-mcp-server,
}:

buildNpmPackage (finalAttrs: {
  pname = "git-mcp-server";
  inherit (source) version src;

  npmDeps = null;
  npmConfigHook = bunConfigHook;

  bunDeps = fetchBunDeps {
    inherit (finalAttrs) pname version src;
    inherit bun;
    # nix-update auto -s bunDeps
    hash = "sha256-p4NKIcqSANyjoLL8KNuNFjHpfOgraq85SOT9hdrAen0=";
  };

  nativeBuildInputs = [ bun ];

  dontNpmInstall = true;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/git-mcp-server}
    install -Dm644 dist/index.js -t $out/lib/git-mcp-server/
    makeWrapper ${lib.getExe bun} $out/bin/git-mcp-server \
      --add-flags "run" \
      --add-flags "-r reflect-metadata" \
      --add-flags "$out/lib/git-mcp-server/index.js"

    runHook postInstall
  '';

  meta = {
    description = "MCP server enabling LLMs and AI agents to interact with Git repos";
    longDescription = ''
      An MCP server enabling LLMs and AI agents to interact with Git repositories.
      Provides tools for comprehensive Git operations including clone, commit,
      branch, diff, log, status, push, pull, merge, rebase, worktree, tag management,
      and more, via the MCP standard. STDIO & HTTP
    '';
    homepage = "https://github.com/cyanheads/git-mcp-server";
    changelog = "https://github.com/cyanheads/git-mcp-server/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ moraxyc ];
    mainProgram = "git-mcp-server";
  };
})
