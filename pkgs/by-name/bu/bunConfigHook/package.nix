{
  makeSetupHook,
  zstd,
}:
makeSetupHook {
  name = "bun-config-hook";
  propagatedBuildInputs = [ zstd ];
} ./script.sh
