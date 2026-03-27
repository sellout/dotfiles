{
  flake-utils,
  home-manager,
  nixpkgs,
  nixpkgs-master,
}: final: prev: let
  # On aarch64-darwin, this gives us a Rosetta fallback, otherwise, it’s a NOP.
  x86_64 =
    if final.stdenv.hostPlatform.system == flake-utils.lib.system.aarch64-darwin
    then import nixpkgs {localSystem = flake-utils.lib.system.x86_64-darwin;}
    else prev;
  master = nixpkgs-master.legacyPackages.${final.stdenv.hostPlatform.system};
in {
  ## Use the home-manager from our inputs (but it doesn’t provide an overlay
  ## itself).
  home-manager =
    ## TODO: This is needed so we pick up the inetutils workaround of
    ##       NixOS/nixpkgs#488689 from Flaky.
    home-manager.packages.${final.stdenv.hostPlatform.system}.home-manager.override
    {inherit (final) inetutils;};

  lexica-ultralegible = final.callPackage ./packages/lexica-ultralegible.nix {};

  ## Used by Signal, but the one in Nixpkgs 25.11 has tests that fail on darwin.
  nodejs_24 = prev.nodejs_24.overrideAttrs (old: {
    doCheck = false;
    sandboxProfile = "";
  });

  ## NB: Python 2 is EOL, so I don’t know why it’s still the default. Since we
  ##     pull Python in for at least some Emacs tooling, ensure that `python`
  ##     means Python 3.
  python = final.python3;
  pythonPackages = final.python3Packages;

  ## The install checks for unison-nix’s UCM derivation can’t be sandboxed, so
  ## we disable them in order to use Garnix.
  unison-ucm = prev.unison-ucm.overrideAttrs (old: {doInstallCheck = false;});
}
