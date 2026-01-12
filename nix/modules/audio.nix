{
  config,
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    darwinConfig = {
      homebrew = {
        casks = ["yousician"];
        masApps = {
          GarageBand = 682658836;
          SoundCloud = 412754595;
        };
      };
      system.startup.chime = false;
    };
    homeConfig = {
      home.packages =
        lib.optionals (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [
          pkgs.spotify
          ## not actually the same app, but access the same service
          (config.lib.local.maybeCask "tidal-hifi" "tidal")
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          # (pkgs.brewCasks.ableton-live-standard.overrideAttrs (old: let
          #   version = "6.0.1"; # version I have a license for
          # in {
          #   inherit version;
          #   src = pkgs.fetchurl {
          #     url = "https://cdn-downloads.ableton.com/channels/${version}/ableton_live_standard_${version}_64.dmg";
          #     hash = "";
          #   };
          # }))
          pkgs.brewCasks.lastfm
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          ## TODO: Lilypond derivation stopped building on darwin in Nixpkgs 25.11.
          pkgs.lilypond
        ]
        ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
          pkgs.cider # we have Music.app on darwin
        ];

      local.nixpkgs.allowedUnfreePackages = [
        "castlabs-electron" # Needed by `pkgs.tidal-hifi`
        "spotify"
      ];

      targets.darwin.defaults.NSGlobalDomain."com.apple.sound.beep.flash" =
        lib.mkIf pkgs.stdenv.hostPlatform.isDarwin true;
    };
    nixosConfig.services.pulseaudio.enable = false;
  };
}
