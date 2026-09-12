let
  collectModules = import ../lib/collect-modules.nix;

  # The directory layout mirrors the package set, so a package's path tells you
  # where its module lives:
  #   pkgs/by-name/<shard>/<name>       <-> by-name/<shard>/<name>
  #   pkgs/toys/by-name/<shard>/<name>  <-> toys/by-name/<shard>/<name>
  #
  # Both roots are scanned, so publishing a module is just dropping
  # `<shard>/<name>/default.nix` in the right place — no registration list to
  # update. `toys/by-name/` does not exist yet and that is fine: a missing root
  # collects to `{ }`.
  serious-modules = collectModules ./by-name;

  toy-modules = collectModules ./toys/by-name;

  all-modules = serious-modules // toy-modules;

  mkSet = moduleSet: {
    imports = builtins.attrValues moduleSet;
  };
in
{
  # Leaf modules only, disjoint by construction. NUR publishes this attribute
  # verbatim as `nur.repos.<repo>.modules.homeManager`, so the official
  # `imports = lib.attrValues nur.repos.<repo>.modules.homeManager;` idiom has to
  # mean "everything, exactly once". Never put a bundle in here: modules
  # accumulate definitions, they do not overwrite each other, so a module
  # reached twice (say through both `default` and `full`) is applied twice.
  modules = all-modules;

  # Bundles. NUR never looks at this attribute, so only consumers that take this
  # flake directly can use them — and they have to pick exactly one.
  sets = {
    default = mkSet serious-modules;
    toys = mkSet toy-modules;
    full = mkSet all-modules;
  };
}
