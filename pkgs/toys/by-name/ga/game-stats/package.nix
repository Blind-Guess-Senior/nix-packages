{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
  stdenv,
}:

let
  # npm 的锁文件带着所有平台的可选二进制包（esbuild / rolldown / tailwind oxide…）。
  # 不过滤的话 riscv64、loong64、sunos 这些都会下，任何一条断流都会让构建挂掉。
  npmCpu =
    {
      x86_64 = "x64";
      aarch64 = "arm64";
      i686 = "ia32";
      armv7l = "arm";
    }
    .${stdenv.hostPlatform.parsed.cpu.name} or stdenv.hostPlatform.parsed.cpu.name;

  npmOs = if stdenv.isDarwin then "darwin" else "linux";
in
buildNpmPackage (finalAttrs: {
  pname = "game-stats";
  version = "0.1.9";

  src = fetchFromGitHub {
    owner = "Rhynic-Studio";
    repo = "GameStats";
    rev = "v${finalAttrs.version}";
    hash = "sha256-zvwoV+n3UeOeGTWH06Hyk3vBVgbzAlIvKFoftcrkhww=";
  };

  npmInstallFlags = [
    "--os=${npmOs}"
    "--cpu=${npmCpu}"
  ];

  npmDepsHash = "sha256-9B12eXZQjghGXJzLu5bVsU27qarwuH6ZEhkIamLToE0=";

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
    platforms = lib.platforms.unix;
  };
})
