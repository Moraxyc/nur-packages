{
  pkgs ? import <nixpkgs> { },
  inputs' ? null,
  system ? builtins.currentSystem,
  ...
}:

{
  exloli-next = pkgs.callPackage ./exloli-next { };
  colmena = (inputs'.colmena.packages.colmena or pkgs.colmena).overrideAttrs (
    finalAttrs: previousAttrs: {
      preBuild =
        previousAttrs.preBuild
        + ''
          substituteInPlace src/nix/hive/mod.rs \
            --replace-fail "flags.set_pure_eval(self.path.is_flake())" "flags.set_pure_eval(false)"
        '';
    }
  );
}
