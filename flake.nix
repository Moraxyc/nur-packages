{
  description = "Moraxyc's NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    systems.url = "github:Moraxyc/nix-systems";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
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
      ];
      systems = import inputs.systems;
      flake = {
        nixosModules = {
          alist = import ./modules/alist.nix;
          gost = import ./modules/gost.nix;
          exloli-next = import ./modules/exloli-next.nix;
          bark-server = import ./modules/bark-server.nix;
          ensurePcr = import ./modules/ensure-pcr.nix;
        };
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
