{
  lib,
  appimageTools,
  fetchurl,
  stdenvNoCC,
  imagemagick,
}:

let
  pname = "wechat";
  version = "4.0.1.11";

  sources = {
    # https://web.archive.org/save
    x86_64-linux = fetchurl {
      url = "https://web.archive.org/web/20250512110825/https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
      hash = "sha256-gBWcNQ1o1AZfNsmu1Vi1Kilqv3YbR+wqOod4XYAeVKo=";
    };
    aarch64-linux = fetchurl {
      url = "https://web.archive.org/web/20250512112413/https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.AppImage";
      hash = "sha256-Rg+FWNgOPC02ILUskQqQmlz1qNb9AMdvLcRWv7NQhGk=";
    };
  };
  src =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ imagemagick ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    install -Dm444 ${appimageContents}/wechat.desktop -t $out/share/applications

    substituteInPlace $out/share/applications/wechat.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'

    # Make desktop Icons
    for RES in 16 24 32 48 64 128 256
    do
        mkdir -p $out/share/icons/hicolor/"$RES"x"$RES"/apps
        magick ${appimageContents}/wechat.png -resize "$RES"x"$RES" $out/share/icons/hicolor/"$RES"x"$RES"/apps/wechat.png
    done
  '';

  meta = {
    description = "Messaging and calling app";
    homepage = "https://www.wechat.com/en/";
    downloadPage = "https://linux.weixin.qq.com/en";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "wechat";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
