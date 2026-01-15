# shellcheck shell=bash

bunConfigHook() {
    echo "Executing bunConfigHook"

    if [ -n "${bunRoot-}" ]; then
      pushd "$bunRoot"
    fi

    if [ -z "${bunDeps-}" ]; then
      echo "Error: 'bunDeps' must be set when using bunConfigHook."
      exit 1
    fi

    if ! command -v "bun" &> /dev/null; then
      echo "Error: 'bun' binary not found in PATH. Consider adding 'pkgs.bun' to 'nativeBuildInputs'." >&2
      exit 1
    fi

    echo "Found 'bun' with version '$(bun --version)'"

    fetcherVersion=$(cat "${bunDeps}/.fetcher-version" || echo 1)

    echo "Using fetcherVersion: $fetcherVersion"

    if [[ $fetcherVersion -ge 1 ]]; then
      tar --zstd -xf "$bunDeps/bun-node-modules.tar.zst"
    fi

    chmod -R +w "."

    echo "Patching scripts"

    while IFS= read -r node_modules; do
        patchShebangs "$node_modules"/{*,.*}
    done < "$bunDeps/.node_modules"

    if [ -n "${bunRoot-}" ]; then
      popd
    fi

    echo "Finished bunConfigHook"
}

postConfigureHooks+=(bunConfigHook)
