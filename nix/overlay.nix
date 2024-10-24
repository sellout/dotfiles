{
  flake-utils,
  home-manager,
  mkalias,
  nixpkgs,
}: final: prev: let
  # On aarch64-darwin, this gives us a Rosetta fallback, otherwise, it’s a NOP.
  x86_64 =
    if final.system == flake-utils.lib.system.aarch64-darwin
    then
      import nixpkgs {
        config =
          import ./modules/nixpkgs-configuration.nix {inherit (nixpkgs) lib;};
        localSystem = flake-utils.lib.system.x86_64-darwin;
      }
    else prev;
in {
  ## Use the home-manager from our inputs (but it doesn’t provide an overlay
  ## itself).
  home-manager = home-manager.packages.${final.system}.home-manager;

  ## Idris 1 doesn’t build on Nixpkgs 23.11.
  idris = final.idris2;

  mkalias = mkalias.packages.${final.system}.mkalias;

  ## I don’t even use Python, but sometimes it’s forced upon me, and Python 2 is
  ## EOL, so don’t let anything use it.
  python = final.python3;
  pythonPackages = final.python3Packages;
}
