{ inputs, ... }:
{
  perSystem =
    {
      system,
      pkgs,
      inputs',
      self',
      config,
      lib,
      ...
    }:
    let
      inherit (config) nixpkgs-options;
      allNixpkgs = {
        inherit pkgs;
        pkgs-cuda = import inputs.nixpkgs (
          nixpkgs-options
          // {
            config = nixpkgs-options.config // {
              cudaSupport = true;
            };
          }
        );
        pkgs-stable = import inputs.nixpkgs-stable nixpkgs-options;
      };

      byNameDir = ../pkgs/by-name;

      getAllPackagePaths =
        dir:
        lib.concatMapAttrs (
          shard: _:
          lib.mapAttrs' (pkg: _: {
            name = pkg;
            value = "${dir}/${shard}/${pkg}/package.nix";
          }) (builtins.readDir "${dir}/${shard}")
        ) (builtins.readDir dir);

      packageFiles = getAllPackagePaths byNameDir;
      sources = pkgs.callPackage ../_sources/generated.nix { };
    in
    {
      packages =
        (import ../pkgs/default.nix {
          inherit
            inputs'
            system
            self'
            sources
            ;
          inherit (allNixpkgs)
            pkgs
            pkgs-stable
            pkgs-cuda
            ;
        })
        // (lib.mapAttrs (
          _name: p: pkgs.lib.callPackageWith (pkgs // { inherit sources; }) p { }
        ) packageFiles);
    };
}
