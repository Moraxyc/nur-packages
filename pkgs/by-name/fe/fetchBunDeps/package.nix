{
  lib,
  stdenvNoCC,
  bun,
  zstd,
  writableTmpDirAsHomeHook,
}:
let
  bunLatest = bun;
  supportedFetcherVersions = [
    1 # just copy node_modules
  ];
in
lib.makeOverridable (
  {
    hash ? "",
    pname,
    bun ? bunLatest,
    bunWorkspaces ? [ ],
    prebunInstall ? "",
    bunInstallFlags ? [ ],
    fetcherVersion ? 1,
    ...
  }@args:
  let
    args' = removeAttrs args [
      "hash"
      "pname"
    ];
    hash' =
      if hash != "" then
        { outputHash = hash; }
      else
        {
          outputHash = "";
          outputHashAlgo = "sha256";
        };

    filterFlags = lib.map (package: "--filter=${package}") bunWorkspaces;
  in
  assert (lib.throwIf (!(builtins.elem fetcherVersion supportedFetcherVersions))
    "fetchbunDeps `fetcherVersion` is not set to a supported value (${lib.concatStringsSep ", " (map toString supportedFetcherVersions)})."
  ) true;

  stdenvNoCC.mkDerivation (
    finalAttrs:
    (
      args'
      // {
        name = "${pname}-bun-deps";

        nativeBuildInputs = [
          bun
          zstd
          writableTmpDirAsHomeHook
        ]
        ++ args.nativeBuildInputs or [ ];

        impureEnvVars =
          lib.fetchers.proxyImpureEnvVars
          ++ [
            "GIT_PROXY_COMMAND"
            "NIX_NPM_REGISTRY"
            "SOCKS_SERVER"
          ]
          ++ args.impureEnvVars or [ ];

        installPhase = ''
          runHook preInstall

          ${prebunInstall}

          export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

          bun install \
            --cpu="*" \
            --os="*" \
            --force \
            --frozen-lockfile \
            --ignore-scripts \
            --no-progress \
            ${lib.escapeShellArgs filterFlags} \
            ${lib.escapeShellArgs bunInstallFlags} \
            ''${NIX_NPM_REGISTRY:+--registry="$NIX_NPM_REGISTRY"} \
            --production

          mkdir -p $out
          echo ${toString fetcherVersion} > $out/.fetcher-version

          runHook postInstall
        '';

        fixupPhase = ''
          runHook preFixup

          echo "Canonicalizing node_modules"
          bun run ${./scripts/canonicalize-node-modules.ts}
          echo "Normalizing bun binaries"
          bun run ${./scripts/normalize-bun-binaries.ts}

          if [[ ${toString fetcherVersion} -ge 1 ]]; then
            (
              find . -type d -name node_modules > $out/.node_modules

              tar --sort=name \
                  --mtime="@''${SOURCE_DATE_EPOCH:-0}" \
                  --owner=0 --group=0 --numeric-owner \
                  --pax-option=exthdr.name=%d/paxheaders/%f,delete=atime,delete=ctime \
                  --zstd -cf $out/bun-node-modules.tar.zst \
                  -T $out/.node_modules
            )
          fi

          runHook postFixup
        '';

        passthru = args.passthru or { } // {
          inherit fetcherVersion;
        };

        dontConfigure = true;
        dontBuild = true;
        outputHashMode = "recursive";
      }
      // hash'
    )
  )
)
