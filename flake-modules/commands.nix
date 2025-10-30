{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      updater = pkgs.writeShellScriptBin "update-packages" ''
        set -euo pipefail

        # Nvfetcher
        KEY_FLAG=""
        [ -f "secrets.toml" ] && KEY_FLAG="$KEY_FLAG -k secrets.toml"
        ${self'.packages.nvfetcher}/bin/nvfetcher $KEY_FLAG --keep-going -c nvfetcher.toml -o _sources "$@"

        # UpdateScript
        nix-shell ${inputs.nixpkgs}/maintainers/scripts/update.nix --argstr maintainer moraxyc
      '';
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          updater
        ]
        ++ (with pkgs; [
          just
          nix-output-monitor
        ]);
      };
    };
}
