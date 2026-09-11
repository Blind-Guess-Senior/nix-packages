{
  lib,
  buildPythonPackage,
  fetchPypi,
  requests,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "python-steamgriddb";
  version = "1.0.5";

  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-A223uwmGXac7QLaM8E+5Z1zRi0kIJ1CS2R83vxYkUGk=";
  };

  build-system = [ setuptools ];

  dependencies = [
    requests
  ];

  pythonImportsCheck = [
    "steamgrid"
  ];

  meta = {
    description = "Python wrapper for the SteamGridDB API.";
    homepage = "https://github.com/ZebcoWeb/python-steamgriddb";
    license = lib.licenses.mit;
  };
})
