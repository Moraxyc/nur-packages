{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  pkgs-cuda ? pkgs,
  sources ? pkgs.callPackage ../_sources/generated.nix { },
  inputs' ? null,
  ...
}:

let
  call-cuda = p: pkgs.lib.callPackageWith (pkgs-cuda // { inherit sources; }) p { };
in
{
  # Cache
  nvfetcher = inputs'.nvfetcher.packages.default;

  self-howdy = call-cuda ./by-name/ho/howdy/package.nix;
  self-linux-enable-ir-emitter = call-cuda ./by-name/li/linux-enable-ir-emitter/package.nix;
}
// (lib.mapAttrs' (
  dir: _:
  lib.nameValuePair "self-${dir}" (pkgs.callPackage ./self/${dir}/package.nix { inherit sources; })
) (builtins.readDir ./self))
