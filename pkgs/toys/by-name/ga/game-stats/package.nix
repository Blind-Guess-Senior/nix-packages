{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
}:

buildNpmPackage (finalAttrs: {
  pname = "game-stats";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "Rhynic-Studio";
    repo = "GameStats";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Fk0/w6J0rf0hddarCXlUyg73aRO0Eu1Rf0dnX4REZCU=";
  };

  npmDepsHash = "sha256-IJdkfSLyPWYGDLTqo0XqSUrddCeB1zwec1w6jSi4aUQ=";

  # Node 24, because the server uses the built in `node:sqlite` module.
  inherit nodejs;

  # `npm run build` = vite build (web) + esbuild (single file server).
  npmBuildScript = "build";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/game-stats
    cp -r dist $out/lib/game-stats/dist
    makeWrapper ${lib.getExe nodejs} $out/bin/game-stats \
      --add-flags "$out/lib/game-stats/dist/server.mjs" \
      --set WEB_ROOT "$out/lib/game-stats/dist/web"
    runHook postInstall
  '';

  passthru.updatePolicy.autoMerge = [
    "patch"
    "minor"
    "major"
  ];

  meta = {
    description = "Tiny LAN web app that keeps score for a handful of games";
    longDescription = ''
      Each game lives at its own path — `/cs2`, `/crash` — and has its own
      tables, its own statistics and its own entry form. Everything is typed in
      by hand, there is no upload and no account: it is meant for a trusted
      network. The whole thing is one process and one SQLite file.
    '';
    homepage = "https://github.com/Rhynic-Studio/GameStats";
    changelog = "https://github.com/Rhynic-Studio/GameStats/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "game-stats";
    platforms = [ "x86_64-linux" ];
  };
})
