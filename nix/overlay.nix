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
  home-manager = home-manager.packages.${final.stdenv.hostPlatform.system}.home-manager;

  ## Idris 1 doesn’t build on Nixpkgs 23.11.
  idris = final.idris2;

  ## TODO: This gives us Karabiner 15, but the nix-darwin module doesn’t yet
  ##       support that version, and since it involves running services, we
  ##       can’t live without it.
  # karabiner-elements = master.karabiner-elements;

  lexica-ultralegible = final.callPackage ./packages/lexica-ultralegible.nix {};

  ## These tests are failing on aarch64-darwin with Nixpkgs 24.11, so disable
  ## them for now.
  nodejs-slim = prev.nodejs-slim.overrideAttrs (old: {
    doCheck = false;
  });

  ## TODO: This should be in Nixpkgs 25.05, but check to see if
  ##       https://github.com/NixOS/nixpkgs/commit/002d82c95fdc43b69b58357791fe4474c0160b0c
  ##       makes it into nixpks-unstable sooner.
  ntfy = master.ntfy;

  ## NB: Python 2 is EOL, so I don’t know why it’s still the default. Since we
  ##     pull Python in for at least some Emacs tooling, ensure that `python`
  ##     means Python 3.
  python = final.python3;
  pythonPackages = final.python3Packages;

  ## The install checks for unison-nix’s UCM derivation can’t be sandboxed, so
  ## we disable them in order to use Garnix.
  unison-ucm = prev.unison-ucm.overrideAttrs (old: {doInstallCheck = false;});
}
