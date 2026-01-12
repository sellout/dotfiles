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
      homebrew.casks = [
        "webex-meetings" # I don’t know how to control auto-update
      ];
    };
    homeConfig = {
      home.packages =
        [
          # pkgs.discord # currently subsumed by ferdium
          # pkgs.element-desktop # currently subsumed by ferdium
          # pkgs.gitter # currently subsumed by ferdium
          ## not available on darwin via Nix
          (config.lib.local.maybeCask "mumble" null)
          pkgs.signal-desktop-bin # src version not supported on darwin
          # pkgs.slack # currently subsumed by ferdium
          # pkgs.wire-desktop # currently subsumed by ferdium
        ]
        ++ lib.optionals (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [
          (config.lib.local.maybeCask "ferdium" null)
          ## GUI not available on darwin via Nix
          (config.lib.local.maybeCask "keybase-gui" "keybase")
          (config.lib.local.maybeCask "simplex-chat-desktop" "simplex")
          pkgs.zoom-us
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          pkgs.brewCasks.adium
          pkgs.brewCasks.gotomeeting
          pkgs.brewCasks.psi
          pkgs.brewCasks.skype
          # pkgs.brewCasks.whatsapp # currently subsumed by ferdium # broken
        ];

      local.nixpkgs.allowedUnfreePackages = [
        "signal-desktop-bin" # actually free – who knows
        "zoom"
      ];
    };
  };
}
