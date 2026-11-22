{
  description = "Static geographic data for Moraxyc's NUR repository";

  outputs = _: {
    cities = import ./cities.nix;
    countries = import ./countries.nix;
  };
}
