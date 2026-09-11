final: prev:
# Recursively get all packages defined by this repo and flatten them.
prev.lib.concatMapAttrs (_: value: value) (
  prev.lib.packagesFromDirectoryRecursive {
    inherit (final) callPackage;
    directory = ../toys;
  }
)
