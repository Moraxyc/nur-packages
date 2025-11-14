{
  lib,
  buildGoModule,
  sources,
}:

buildGoModule (finalAttrs: {
  pname = "flapalerted";
  version = sources.flapalerted.date;

  inherit (sources.flapalerted) src;

  vendorHash = null;

  ldflags = [ "-s" ];

  meta = {
    description = "BGP Update based flap detection";
    homepage = "https://github.com/Kioubit/FlapAlerted";
    # No license
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ moraxyc ];
    mainProgram = "FlapAlerted";
  };
})
