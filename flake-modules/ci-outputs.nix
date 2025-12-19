{
  lib,
  flake-parts-lib,
  ...
}:
{
  imports = [
    (flake-parts-lib.mkTransposedPerSystemModule {
      name = "ciPackages";
      option = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.package;
        default = [ ];
      };
      file = ./ci-outputs.nix;
    })
  ];

  perSystem =
    {
      self',
      pkgs,
      ...
    }:
    let
      inherit (pkgs.callPackage ../helpers/filters.nix { }) isBuildable;
    in
    {
      ciPackages = lib.filterAttrs isBuildable self'.legacyPackages;
    };
}
