# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `overlays`,
# `nixosModules`, `homeModules`, `darwinModules` and `flakeModules`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{
  pkgs ? import <nixpkgs> { },
}:

let
  overlays = import ./overlays;
  packageOverlay = overlays.full;
  packageSet = pkgs.extend packageOverlay;
  packageAttrs = packageOverlay packageSet pkgs;
in
{
  # The `lib`, `overlays`, `nixosModules`, `homeModules`,
  # `darwinModules` and `flakeModules` names are special
  lib = import ./lib { inherit pkgs; }; # functions

  nixosModules = (import ./nixos-modules).modules; # NixOS modules (leaves only)
  nixosModuleSets = (import ./nixos-modules).sets; # NixOS module bundles

  homeModules = (import ./home-modules).modules; # Home Manager modules (leaves only)
  homeModuleSets = (import ./home-modules).sets; # Home Manager module bundles

  # darwinModules = { }; # nix-darwin modules

  # flakeModules = { }; # flake-parts modules

  overlays = import ./overlays; # nixpkgs overlays

}
// pkgs.lib.filterAttrs (_: value: pkgs.lib.isDerivation value) packageAttrs
