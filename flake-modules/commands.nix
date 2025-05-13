_: {
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      nvfetcher = pkgs.writeShellScriptBin "nvfetcher" ''
        set -euo pipefail
        KEY_FLAG=""
        [ -f "secrets.toml" ] && KEY_FLAG="$KEY_FLAG -k secrets.toml"
        ${self'.packages.nvfetcher}/bin/nvfetcher $KEY_FLAG --keep-going -c nvfetcher.toml -o _sources "$@"
      '';
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs =
          [
            nvfetcher
          ]
          ++ (with pkgs; [
            just
            nix-output-monitor
          ]);
      };
    };
}
