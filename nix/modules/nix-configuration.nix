{
  config,
  lib,
  nixpkgs,
  pkgs,
  ...
}: {
  nix = {
    ## Set the registry’s Nixpkgs to match this flake’s.
    registry.nixpkgs.flake = nixpkgs;

    settings = {
      ## This is generally superseded by `config.programs.starship`, but in some
      ## subshells, remote machines, etc. that’s not there, so this gives us
      ## _something_.
      bash-prompt-prefix = "❄️";
      extra-experimental-features = [
        "flakes"
        "nix-command"
        "repl-flake" # provides a `:lf` (load flake) command in `nix repl`
      ];
      extra-substituters = ["https://cache.garnix.io"];
      extra-trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
      ## NIX_PATH is still used by many useful tools, so we set it to the same
      ## value as the one used by this flake. For more information, see
      ## https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry
      nix-path = lib.mkForce "nixpkgs=${nixpkgs}";
      ## TODO: Enable globally once NixOS/nix#4119 is fixed.
      sandbox = !pkgs.stdenv.hostPlatform.isDarwin;
      use-xdg-base-directories = true;
    };
  };
}
