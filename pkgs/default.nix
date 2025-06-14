{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  pkgs-stable ? pkgs,
  pkgs-cuda ? pkgs,
  sources ? pkgs.callPackage ../_sources/generated.nix { },
  inputs' ? null,
  inputs ? null,
  system ? builtins.currentSystem,
  ...
}:

let
  call = p: pkgs.lib.callPackageWith (pkgs // { inherit sources; }) p { };
  call-cuda = p: pkgs.lib.callPackageWith (pkgs-cuda // { inherit sources; }) p { };
  call-stable = p: pkgs.lib.callPackageWith (pkgs-stable // { inherit sources; }) p { };
in
{
  # Cache
  nvfetcher = inputs'.nvfetcher.packages.default;

  self-howdy = call-cuda ./by-name/ho/howdy/package.nix;
  self-linux-enable-ir-emitter = call-cuda ./by-name/li/linux-enable-ir-emitter/package.nix;

  hath-rust = throw "hath-rust has been merged into nixpkgs/nixos-unstable";
}
// (lib.mapAttrs' (
  dir: _:
  lib.nameValuePair "self-${dir}" (pkgs.callPackage ./self/${dir}/package.nix { inherit sources; })
) (builtins.readDir ./self))
