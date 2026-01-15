{
  stdenv,
  sources,
  source ? sources.nvfetcher,
}:
(import source.src).packages.${stdenv.hostPlatform.system}.default.overrideAttrs (
  finalAttrs: prevAttrs: {
    passthru = (prevAttrs.passthru or { }) // {
      _ignoreOverride = true;
    };
  }
)
