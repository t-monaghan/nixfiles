{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "notunes";
  version = "3.5";

  src = fetchurl {
    url = "https://github.com/tombonez/noTunes/releases/download/v${version}/noTunes-${version}.zip";
    hash = "sha256-B4Nc+fO/MU0R8uvlKAcqIA/6LVXzjeWQhZecLUduo9U=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [unzip];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -r noTunes.app $out/Applications/noTunes.app
    runHook postInstall
  '';

  meta = with lib; {
    description = "A simple macOS application that will prevent iTunes or Apple Music from launching";
    homepage = "https://github.com/tombonez/noTunes";
    license = licenses.mit;
    platforms = platforms.darwin;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
  };
}
