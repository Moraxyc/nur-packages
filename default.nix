{
  cities = builtins.fromJSON (builtins.readFile ./cities.json);
  countries = builtins.fromJSON (builtins.readFile ./countries.json);
}
