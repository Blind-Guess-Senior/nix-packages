{
  description = "Blind Guess Senior's personal NUR repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      overlays = import ./overlays;
      overlay = overlays.full;

      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      inherit overlays;

      legacyPackages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        pkgs
      );

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          extendedPkgs = pkgs.extend overlay;
          ownPackages = overlay extendedPkgs pkgs;
        in
        # Get packages (in ownPackages) that match conditions
        nixpkgs.lib.filterAttrs (
          _name: value:
          nixpkgs.lib.isDerivation value # Exclude list (e.g. pythonPackagesExtensions), only contains derivations
          && nixpkgs.lib.meta.availableOn { inherit system; } value
        ) ownPackages
      );

      # NUR publishes `nixosModules` / `homeModules` verbatim, so those hold leaf
      # modules only and `lib.attrValues` over them means "everything, once".
      # The bundles (default / toys / full) live in the `*ModuleSets` outputs,
      # which NUR ignores — pick exactly one of them per host.
      nixosModules = (import ./nixos-modules).modules;
      nixosModuleSets = (import ./nixos-modules).sets;

      homeModules = (import ./home-modules).modules;
      homeModuleSets = (import ./home-modules).sets;

      # darwinModules = import ./darwin-modules;

      # flakeModules = import ./flake-modules;
    };
}
