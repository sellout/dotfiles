{lib, ...}: {
  # The preferred location of applications is, in order:
  # 1. home.nix#home.packages (~/Applications/Home Manager Apps)
  # 1a. pkgs.nixcasks
  # 2. environment.systemPackages (/Applications/Nix Apps)
  # 3. homebrew.casks (/Applications/Homebrew Apps)
  # 4. homebrew.masApps (/Applications)
  # 5. manually installed (~/Applications)
  #
  # NB: The last two may also end up with some additional apps in them, because
  #     some apps do not like to be run from other locations. E.g., 1Password is
  #     managed by `homebrew.casks`, but is installed in /Applications so that
  #     the browser plugins can communicate with it. These apps should have
  #     comments by them indicating where they live and why.
  #
  # NB: Ideally this would be managed in home.nix, but that's not yet supported.
  homebrew = {
    enable = true;
    ## TODO: This is a workaround for LnL7/nix-darwin#1314.
    brews = lib.mkForce [];
    caskArgs = {
      appdir = "/Applications/Homebrew Apps";
      fontdir = "/Library/Fonts/Homebrew Fonts";
    };
    ## NB: `greedy = true;` in here means that I’ve ensured that the app _won’t_
    ##     auto-update. However, that will not apply when this transfers to a
    ##     new machine, so need a better approach. See
    ##     https://docs.brew.sh/FAQ#why-arent-some-apps-included-during-brew-upgrade
    ##     Use
    ##   > brew info --cask --json=v2 $(brew ls --cask) \
    ##   >   | nix shell nixpkgs#jq \
    ##   >     --command jq -r '.casks[]|select(.auto_updates==true)|.token'
    ##     to see which casks need `greedy = true;` in order to be upgraded by
    ##     Homebrew.
    casks = [
      ## This is also installed by home.nix#home.packages, but that _probably_
      ## has even more of the “wrong location” issue mentioned below, as it’s
      ## simply an alias to the Nix store, so keep this around until I’m willing
      ## to fight with that.
      {
        name = "1password";
        ## Doesn’t integrate with browsers properly if moved. Search email for
        ## #PKL-58745-842 for more info.
        args.appdir = "/Applications";
        greedy = true;
      }
      "bitcoin-core"
      ## NB: in nixcasks, but fails in `copyApps` (see jcszymansk/nixcasks#19)
      "calibre"
      "google-drive" # doesn't respect appdir
      "powerphotos"
      "timemachineeditor"
      # "virtualbox" # requires Intel architecture
      {
        # not available on darwin via Nix
        name = "vlc";
        greedy = true;
      }
      "webex-meetings" # I don’t know how to control auto-update
      # "whatsapp" # currently subsumed by ferdium
      # "wire" # currently subsumed by ferdium
      # not available on darwin via Nix, but seems like it should be
      "xquartz" # doesn't respect appdir # broken in Nix
    ];
    global.brewfile = true;
    masApps = {
      "1Password for Safari" = 1569813296;
      "Amazon Kindle" = 302584613;
      Deliveries = 290986013;
      iMovie = 408981434;
      Keynote = 409183694;
      Numbers = 409203825;
      Pages = 409201541;
      "Prime Video" = 545519333;
      reMarkable = 1276493162;
      "Remote Mouse" = 403195710;
      ## NB: Evernote has killed Skitch, and it’s subsequently been removed from
      ##     Homebrew (https://github.com/orgs/Homebrew/discussions/6243).
      ##     However, we can still get it from the App store, so do so for now.
      Skitch = 425955336;
    };
    ## NB: These settings unfortunately make `darwin-rebuild switch`
    ##     non-idempotent, but the alternative is having Homebrew just be
    ##     outdated forever (because I’ll never do it manually).
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };
  };

  ## Don’t auto-upgrade from the Mac App Store (this is handled by
  ## `homebrew.masApps`).
  system.defaults.CustomSystemPreferences."com.apple.commerce".AutoUpdate = false;
}
