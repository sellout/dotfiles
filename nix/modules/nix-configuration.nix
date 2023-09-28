{
  lib,
  pkgs,
  ...
}: {
  nix = {
    registry.nixpkgs = {
      from = {
        id = "nixpkgs";
        type = "indirect";
      };
      to = {
        type = "github";
        owner = "nixpkgs";
        repo = "nixpkgs";
        ref = "release-23.05";
      };
    };

    settings = {
      ## This is generally superseded by `programs.starship`, but in some subshells,
      ## remote machines, etc. that’s not there, so this gives us _something_.
      bash-prompt-prefix = "❄️";
      extra-experimental-features = ["flakes" "nix-command" "recursive-nix"];
      extra-substituters = ["https://cache.garnix.io"];
      extra-trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
      trusted-users = ["@wheel" "greg"];
      # TODO: Enable globally once NixOS/nix#4119 is fixed.
      sandbox = !pkgs.stdenv.hostPlatform.isDarwin;
    };
  };
}
