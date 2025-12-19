{
  description = "Moraxyc's NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    systems.url = "github:Moraxyc/nix-systems";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };
  outputs =
    {
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-modules/commands.nix
        ./flake-modules/nixpkgs-options.nix
        ./flake-modules/by-name.nix
        ./flake-modules/modules.nix
        ./flake-modules/ci-outputs.nix
        ./flake-modules/nur-outputs.nix
      ];
      systems = import inputs.systems;
      flake = {
        lib = import ./lib;
      };
      perSystem =
        {
          pkgs,
          ...
        }:
        {
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
