{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    let
      baseDir = ../pkgs/by-name;

      readDirs = path: lib.filterAttrs (n: v: v == "directory") (builtins.readDir path);

      nurPackages = lib.makeScope pkgs.newScope (
        self:
        let
          shards = builtins.attrNames (readDirs baseDir);
          processShard =
            shard:
            let
              shardDir = baseDir + "/${shard}";
              packageNames = builtins.attrNames (readDirs shardDir);
            in
            lib.genAttrs packageNames (name: self.callPackage (shardDir + "/${name}/package.nix") { });
        in
        if builtins.pathExists baseDir then
          lib.foldl' (acc: shard: acc // (processShard shard)) { } shards
        else
          { }
      );
    in
    {
      legacyPackages = nurPackages;
    };
}
