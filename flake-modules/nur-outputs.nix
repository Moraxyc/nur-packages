{
  lib,
  flake-parts-lib,
  ...
}:
{
  imports = [
    (flake-parts-lib.mkTransposedPerSystemModule {
      name = "nurPackages";
      option = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.package;
        default = [ ];
      };
      file = ./nur-outputs.nix;
    })
  ];

  perSystem =
    {
      self',
      pkgs,
      ...
    }:
    let
      inherit (pkgs.callPackage ../helpers/filters.nix { }) isExport;
    in
    {
      nurPackages = lib.filterAttrs isExport self'.legacyPackages;
    };
}
