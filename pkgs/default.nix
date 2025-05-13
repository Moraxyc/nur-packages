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
  howdy = call-cuda ./howdy;
  linux-enable-ir-emitter = call-cuda ./linux-enable-ir-emitter;

  # Cache
  nvfetcher = inputs'.nvfetcher.packages.default;

  self = lib.mapAttrs' (
    dir: _: lib.nameValuePair dir (pkgs.callPackage ./self/${dir}/package.nix { inherit sources; })
  ) (builtins.readDir ./self);
}
