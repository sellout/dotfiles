{
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    darwinConfig = {
      homebrew = {
        casks = [
          # not available on darwin via Nix
          # I don’t know how to control auto-update
          "steam"
        ];
        masApps.Robotek = 462238382;
      };
    };

    homeConfig = {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.nixcasks.marathon
      ];
    };

    nixosConfig = {
      local.nixpkgs = {
        enable = true;
        allowedUnfreePackages = [
          "steam"
          "steam-unwrapped"
        ];
      };
      programs.steam = {
        enable = pkgs.system == "x86_64-linux";
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;
      };
    };
  };
}
