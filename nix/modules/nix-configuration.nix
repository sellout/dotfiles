{
  flaky,
  lib,
  math,
  nixcasks,
  nixpkgs,
  nixpkgs-master,
  nixpkgs-unstable,
  options,
  pkgs,
  ...
}: let
  ## We pull the preferred Cachix information from the Nix CI configuration.
  ## TODO: We should be able to get this from the project configuration that
  ##       generates this file.
  cachix = (import ../../nix-ci.nix).cachix;

  nix = {
    registry = {
      ## Set the registry’s Nixpkgs to match this flake’s.
      nixpkgs.flake = nixpkgs;
      ## These allow for quick checks against newer Nixpkgs (e.g., `nix shell
      ## nixpkgs-master#rustup`)
      nixpkgs-master.flake = nixpkgs-master;
      nixpkgs-unstable.flake = nixpkgs-unstable;
      ## Allows `env#` to reference the templates, devShells, etc. from Flaky
      ## environments.
      env.to = {
        type = "github";
        owner = "sellout";
        repo = "flaky-environments";
      };
      ## To make it easy to try Homebrew packages without modifying the
      ## configuration.
      nixcasks.flake = nixcasks;
    };

    settings = {
      ## Require flakes to be explicit about IFD, and encourage the use of
      ## Project Manager to avoid it.
      allow-import-from-derivation = false;
      ## This causes builds to optimize after themselves, incrementally.
      ## TODO: Make this `true` once NixOS/nix#7273 is fixed.
      auto-optimise-store = !pkgs.stdenv.hostPlatform.isDarwin;
      ## This is generally superseded by `config.programs.starship`, but in some
      ## subshells, remote machines, etc. that’s not there, so this gives us
      ## _something_.
      bash-prompt-prefix = "❄️";
      ## Avoid stalling downloads by increasing the download buffer from the
      ## default 64 MiB
      ## (https://nix.dev/manual/nix/2.29/command-ref/conf-file.html#conf-download-buffer-size).
      ## This is likely caused by the buffer being used (incorrectly) when
      ## pulling substitutes, even locally (see NixOS/nix#11728). It could be
      ## possible to optimize this by scaling it inversely to the CPU speed on a
      ## given machine, but it doesn’t seem worth the effort.
      download-buffer-size = math.pow 2 29; # 512 MiB
      extra-experimental-features = [
        "flakes"
        "nix-command"
      ];
      extra-trusted-public-keys = [cachix.public-key];
      extra-trusted-substituters = ["https://${cachix.name}.cachix.org"];
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

  packages = [
    ## Make it easy to figure out why derivations are being built.
    ## https://github.com/Gabriella439/nix-diff#readme
    pkgs.nix-diff
    ## Figure out which roots are eating up your disk.
    ## https://github.com/symphorien/nix-du#readme
    pkgs.nix-du
    ## Various tools to simplify Nix usage.
    ## https://github.com/madjar/nox#readme
    pkgs.nox
  ];

  systemPackages =
    packages
    ++ [
      ## Allow users to manage their home directory with Home Manager.
      pkgs.home-manager
    ];
in {
  config = flaky.lib.multiConfig options {
    darwinConfig = {
      inherit nix;
      environment = {inherit systemPackages;};
    };
    homeConfig = {
      inherit nix;
      home = {inherit packages;};
    };
    nixosConfig = {
      inherit nix;
      environment = {inherit systemPackages;};
    };
  };
}
