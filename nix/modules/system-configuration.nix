## This is configuration shared between various systems (NixOS, nix-darwin,
## system-manager, etc.)
{
  dotfiles,
  pkgs,
  ...
}: {
  imports = [
    ./fonts.nix
    ./games.nix
    ./garnix-cache.nix
    ./input-devices.nix
    ./locale.nix
    ./nix-configuration.nix
    ./nixpkgs-configuration.nix
    ./storage.nix
    ./vcs
  ];

  environment = {
    extraOutputsToInstall = ["devdoc" "doc" "man"];
    systemPackages = [
      ## Nix
      pkgs.home-manager
      pkgs.nix-du
      pkgs.nox
      ## system
      pkgs.cacert
      pkgs.coreutils
      pkgs.gnupg
      pkgs.yubikey-manager
      pkgs.yubikey-personalization
    ];
  };

  garnix.cache.enable = true;

  nix = {
    ## Remove old-style tools & configs, preferring flakes.
    channel.enable = false;
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    ## Runs `nix-store --optimise` on a timer.
    optimise.automatic = true;
  };

  nixpkgs.overlays = [dotfiles.overlays.nixos];

  services = {
    openssh.enable = false; # subsumed by tailscale

    tailscale.enable = true;
  };
}
