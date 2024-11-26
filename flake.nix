{
  description = "Moraxyc's NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      flake = {

        nixosModules = {
          alist = import ./modules/alist.nix;
          gost = import ./modules/gost.nix;
          exloli-next = import ./modules/exloli-next.nix;
          bark-server = import ./modules/bark-server.nix;
        };

        lib = import ./lib;
      };
      perSystem =
        {
          system,
          pkgs,
          inputs',
          ...
        }:
        {
          packages = import ./pkgs/default.nix {
            pkgs = import nixpkgs { inherit system; };
            inherit inputs' system self;
          };
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
