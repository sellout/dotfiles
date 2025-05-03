{
  lib,
  nixpkgs,
  pkgs,
  ...
}: {
  nix = {
    registry = {
      ## Set the registry’s Nixpkgs to match this flake’s.
      nixpkgs.flake = nixpkgs;
      ## Allows `env#` to reference the templates, devShells, etc. from Flaky
      ## environments.
      env.to = {
        type = "github";
        owner = "sellout";
        repo = "flaky-environments";
      };
    };

    settings = {
      ## This causes builds to optimize after themselves, incrementally.
      ## TODO: Make this `true` once NixOS/nix#7273 is fixed.
      auto-optimise-store = !pkgs.stdenv.hostPlatform.isDarwin;
      ## This is generally superseded by `config.programs.starship`, but in some
      ## subshells, remote machines, etc. that’s not there, so this gives us
      ## _something_.
      bash-prompt-prefix = "❄️";
      extra-experimental-features = [
        "flakes"
        "nix-command"
      ];
      ## NIX_PATH is still used by many useful tools, so we set it to the same
      ## value as the one used by this flake. For more information, see
      ## https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry
      nix-path = lib.mkForce "nixpkgs=${nixpkgs}";
      ## TODO: Enable globally once NixOS/nix#4119 is fixed.
      sandbox = !pkgs.stdenv.hostPlatform.isDarwin;
      show-trace = true;
      use-xdg-base-directories = true;
    };
  };
}
