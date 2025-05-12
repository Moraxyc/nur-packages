let
  flakePackages = (builtins.getFlake (toString ./.)).outputs.packages;
in
flakePackages.${builtins.currentSystem}
