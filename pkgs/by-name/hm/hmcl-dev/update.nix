{
  writeShellApplication,
  nix,
  nix-update,
  curl,
  common-updater-scripts,
  jq,
}:

writeShellApplication {
  name = "update-hmcl";
  runtimeInputs = [
    curl
    jq
    nix
    common-updater-scripts
    nix-update
  ];

  text = ''
    # get old info
    oldVersion=$(nix-instantiate --eval --strict -A "hmcl-dev.version" | jq -e -r)

    get_latest_release() {
        curl --fail ''${GITHUB_TOKEN:+ -H "Authorization: bearer $GITHUB_TOKEN"} \
             -s "https://api.github.com/repos/HMCL-dev/HMCL/tags" | jq -r '.[0].name'
    }

    version=$(get_latest_release)
    version="''${version#v-}"

    if [[ "$oldVersion" == "$version" ]]; then
        echo "Already up to date!"
        exit 0
    fi

    nix-update hmcl-dev --version="$version"
    update-source-version hmcl-dev --source-key=jar --ignore-same-version
    $(nix-build -A hmcl-dev.mitmCache.updateScript)
  '';
}
