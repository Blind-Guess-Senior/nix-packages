{
  lib,
  fetchFromGitHub,
  python313Packages,
}:

python313Packages.buildPythonApplication (finalAttrs: {
  pname = "lutris-coverup";
  version = "0.1.2";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "callmenoodles";
    repo = "lutris-coverup";
    rev = "v${finalAttrs.version}";
    hash = "sha256-LaMHeEOib5AE4U95rwuhYyXmLwbmAfY+EUk8V3eMoW0=";
  };

  postPatch = ''
    # Fix project metadata. Deprecated 'dotenv' -> 'python-dotenv'
    substituteInPlace pyproject.toml --replace-fail '"dotenv>=0.9.9"' '"python-dotenv>=1.2.1"'

    # Make project exe 'lucov' -> 'lutris-coverup'
    substituteInPlace pyproject.toml --replace-fail 'lucov = "lutris_coverup.cli:cli"' 'lutris-coverup = "lutris_coverup.cli:cli"'

    # Supply missing build system info
    cat >> pyproject.toml << 'EOF'

    [build-system]
    requires = ["pdm-backend"]
    build-backend = "pdm.backend"
    EOF
  '';

  build-system = [ python313Packages.pdm-backend ];

  dependencies = with python313Packages; [
    click
    pillow
    python-dotenv
    python-steamgriddb
    requests
  ];

  pythonImportsCheck = [ "lutris_coverup.cli" ];

  meta = {
    description = "Download missing cover art, banners, and icons for Lutris";
    homepage = "https://github.com/callmenoodles/lutris-coverup";
    changelog = "https://github.com/callmenoodles/lutris-coverup/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "lutris-coverup";
    platforms = lib.platforms.linux;
  };
})
