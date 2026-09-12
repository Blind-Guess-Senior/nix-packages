let
  serious-modules = {
    # Add serious NixOS modules here, e.g. my-module = import ./my-module;
  };

  toy-modules = {
    movie-pool = import ./movie-pool;
  };

  all-modules = serious-modules // toy-modules;

  mkSet = moduleSet: {
    imports = builtins.attrValues moduleSet;
  };
in
{
  # Leaf modules only, disjoint by construction. NUR publishes this attribute
  # verbatim as `nur.repos.<repo>.modules.nixos`, so the official
  # `imports = lib.attrValues nur.repos.<repo>.modules.nixos;` idiom has to mean
  # "everything, exactly once". Never put a bundle in here: modules accumulate
  # definitions, they do not overwrite each other, so a module reached twice
  # (say through both `default` and `full`) is applied twice.
  modules = all-modules;

  # Bundles. NUR never looks at this attribute, so only consumers that take this
  # flake directly can use them — and they have to pick exactly one.
  sets = {
    default = mkSet serious-modules;
    toys = mkSet toy-modules;
    full = mkSet all-modules;
  };
}
