{ inputs, ... }:
let
  packages = builtins.concatStringsSep " " [
    "hmcl-dev"
  ];
in
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      updater = pkgs.writeShellScriptBin "update-packages" ''
        set -euo pipefail

        # Nvfetcher
        KEY_FLAG=""
        [ -f "secrets.toml" ] && KEY_FLAG="$KEY_FLAG -k secrets.toml"
        ${lib.getExe pkgs.nvfetcher} $KEY_FLAG --keep-going -c nvfetcher.toml -o _sources "$@"

        # UpdateScript
        for PACKAGE in ${packages}; do
          echo "Updating package '$PACKAGE'."
          ${lib.getExe pkgs.nix-update} --flake --commit "$PACKAGE"
        done
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
