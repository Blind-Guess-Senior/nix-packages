# Collect every `<root>/<shard>/<name>/default.nix` into `{ <name> = <module>; }`.
#
# This is the module counterpart of `lib.packagesFromDirectoryRecursive`: same
# sharded `by-name` layout, but it *imports* the file instead of calling it with
# a package set, because a module is a function of the module system rather than
# of `pkgs`.
#
# A missing root yields `{ }`, which matters in practice: git cannot track an
# empty directory, so `toys/by-name/` simply does not exist until the first toy
# module lands.
root:
let
  entries = if builtins.pathExists root then builtins.readDir root else { };

  shards = builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries);

  collectShard =
    shard:
    let
      dir = root + "/${shard}";
      shardEntries = builtins.readDir dir;
    in
    builtins.concatMap (
      name:
      if shardEntries.${name} == "directory" && builtins.pathExists (dir + "/${name}/default.nix") then
        [
          {
            inherit name;
            value = import (dir + "/${name}");
          }
        ]
      else
        [ ]
    ) (builtins.attrNames shardEntries);
in
builtins.listToAttrs (builtins.concatMap collectShard shards)
