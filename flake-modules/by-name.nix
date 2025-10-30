{ inputs, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];
  perSystem = _: {
    pkgsDirectory = ../packages;
  };
}
