{
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-question";
  version = "0.5.6";

  src = fetchurl {
    url = "https://registry.npmjs.org/@ravshansbox/pi-question/-/pi-question-${finalAttrs.version}.tgz";
    hash = "sha256-8cVSccT+utP/kICTJU9GZjX05X8pNLBv9AzTd8codKY=";
  };

  patches = [./patches/question-program-status.patch];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp index.ts package.json LICENSE README.md "$out/"
    runHook postInstall
  '';
})
