final: prev:
{
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ (import ./python-packages.nix) ];
}
//
  # Recursively get all no-toy packages defined by this repo and flatten them.
  prev.lib.concatMapAttrs (_: value: value) (
    prev.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../by-name;
    }
  )
