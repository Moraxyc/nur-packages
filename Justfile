build target:
    nix build ".{{target}}"

check:
    nix flake check .

update:
    nix flake update
    nvfetcher -c nvfetcher.toml -o _sources
