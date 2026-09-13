{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "movie-pool";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "Blind-Guess-Senior";
    repo = "movie-pool";
    rev = "v${finalAttrs.version}";
    hash = "sha256-DMPjqeDSItRrZM2s8YO91DJ6sjvQMokeQjtE6Xa821o=";
  };

  # The app is written against the standard library only, so there is nothing
  # to vendor and no go.sum to check.
  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  passthru.updatePolicy.autoMerge = [
    "patch"
    "minor"
    "major"
  ];

  meta = {
    description = "Tiny LAN web app that collects movie wishes and draws one at random every phase";
    longDescription = ''
      Everyone on the LAN can look at the movie being watched right now and at
      the ones already watched, but never at the pool itself. Anyone can claim
      a name (no password, it is meant for a trusted network) and drop up to a
      configurable number of movie wishes into the pool. One wish is drawn at
      random per phase — weekly, on Wednesday at 20:00 by default — and as soon
      as the pool runs dry a new cycle starts and everybody's quota resets.
    '';
    homepage = "https://github.com/Blind-Guess-Senior/movie-pool";
    changelog = "https://github.com/Blind-Guess-Senior/movie-pool/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "movie-pool";
    platforms = lib.platforms.unix;
  };
})
