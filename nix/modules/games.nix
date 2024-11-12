{
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
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
          "steam-original"
          "steam-run"
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
