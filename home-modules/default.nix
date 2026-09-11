let
  modules = {
    lutris-coverup = import ./lutris-coverup;
  };

  toy-modules = {
  };

  mkModule = moduleSet: {
    imports = builtins.attrValues moduleSet;
  };
in
modules
// {
  default = mkModule modules;
  toys = mkModule toy-modules;
  full = mkModule (modules // toy-modules);
}
