## This is configuration shared between various systems (NixOS, nix-darwin,
## system-manager, etc.)
{pkgs, ...}: {
  imports = [
    ./audio.nix
    ./communication.nix
    ./direnv.nix
    ./fonts.nix
    ./games.nix
    ./garnix-cache.nix
    ./input-devices.nix
    ./locale.nix
    ./nix-configuration.nix
    ./nixos-wiki.nix
    ./nixpkgs-configuration.nix
    ./pim.nix
    ./programming
    ./storage.nix
    ./vcs
  ];

  environment = {
    extraOutputsToInstall = ["devdoc" "doc" "man"];
    systemPackages = [
      pkgs.cacert
      pkgs.coreutils
      pkgs.gnupg
      pkgs.yubikey-manager
      pkgs.yubikey-personalization
    ];
  };

  ## Don’t let Home Manager conflicts get in the way of system updates.
  home-manager.backupFileExtension = "before-home-manager";

  ## This service is now dead, but may rise again.
  garnix.cache.enable = false;

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

  services = {
    openssh.enable = false; # subsumed by tailscale

    tailscale.enable = true;
  };
}
