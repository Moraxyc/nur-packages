{
  pkgs ? import <nixpkgs> { },
  inputs' ? null,
  system ? builtins.currentSystem,
  ...
}:

{
  exloli-next = pkgs.callPackage ./exloli-next { };
  pam-watchid = pkgs.callPackage ./pam-watchid { };
}
