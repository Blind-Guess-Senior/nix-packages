let
  default = import ../pkgs/top-level/default-packages.nix;
  toys = import ../pkgs/top-level/toy-packages.nix;

  full =
    final: prev:
    let
      defaultAttrs = default final prev;
    in
    defaultAttrs // toys final (prev // defaultAttrs);
in
{
  inherit default toys full;
}
