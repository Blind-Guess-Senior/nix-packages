final: prev:
# Recursively get all packages defined by this repo and flatten them.
# Toys mirror the shape of the serious package set: `toys/by-name/<shard>/<name>`
# flattens to `pkgs.<name>`, exactly like `pkgs/by-name` does above.
prev.lib.concatMapAttrs (_: value: value) (
  prev.lib.packagesFromDirectoryRecursive {
    inherit (final) callPackage;
    directory = ../toys/by-name;
  }
)
