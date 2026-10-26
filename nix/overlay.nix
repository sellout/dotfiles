{
  flake-utils,
  home-manager,
  nixpkgs,
  nixpkgs-unstable,
}: final: prev: let
  # On aarch64-darwin, this gives us a Rosetta fallback, otherwise, it’s a NOP.
  x86_64 =
    if final.stdenv.hostPlatform.system == flake-utils.lib.system.aarch64-darwin
    then import nixpkgs {localSystem = flake-utils.lib.system.x86_64-darwin;}
    else prev;
  unstable = nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system};
in {
  ## Use the home-manager from our inputs (but it doesn’t provide an overlay
  ## itself).
  home-manager =
    ## TODO: This is needed so we pick up the inetutils workaround of
    ##       NixOS/nixpkgs#488689 from Flaky.
    home-manager.packages.${final.stdenv.hostPlatform.system}.home-manager.override
    {inherit (final) inetutils;};

  lexica-ultralegible = final.callPackage ./packages/lexica-ultralegible.nix {};

  ## Signal expires itself, and the Nixpkgs releases often have a version that
  ## already expired. `master` is likely to be more up-to-date, but it also
  ## increases the chances of having to build Electron, so we take it from
  ## `nixpkgs-unstable`.
  signal-desktop = unstable.signal-desktop;

  ## The install checks for unison-nix’s UCM derivation can’t be sandboxed, so
  ## we disable them in order to use Garnix.
  unison-ucm = prev.unison-ucm.overrideAttrs (old: {doInstallCheck = false;});

  ## WAIT: The version in Nixpkgs 26.05 doesn’t support ignore files. Remove
  ##       when
  ##       https://github.com/NixOS/nixpkgs/commit/d0baf01bdc3f93ffe56210daa7f15e50bfb0ac52
  ##       is in a release.
  xdg-ninja = unstable.xdg-ninja;
}
