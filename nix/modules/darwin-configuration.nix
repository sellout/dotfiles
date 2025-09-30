### Most configuration should be managed per-user via home-manager. This only
### contains things that are provided globally for some reason.
{
  config,
  dotfiles,
  lib,
  pkgs,
  ...
}: {
  imports = [./system-configuration.nix];

  environment = {
    etc.hosts.text = config.lib.local.toHostsFile {
      # localhost is used to configure the loopback interface when the system is
      # booting. Do not change this entry.
      "127.0.0.1" = ["localhost"];
      "255.255.255.255" = ["broadcasthost"];
      "::1" = ["localhost"];
      "fe80::1%lo0" = ["localhost"];
    };
    pathsToLink = ["/share/fonts"];
    ## TODO: This is a workaround for LnL7/nix-darwin#947.
    profiles = lib.mkOrder 801 [
      "$XDG_STATE_HOME/nix/profile"
      "$HOME/.local/state/nix/profile"
    ];
    systemPackages = [
      ## remote connections
      pkgs.mosh # NixOS has a module for this, nix-darwin doesn’t.
    ];
    systemPath = [
      # TODO: Support this via the homebrew module.
      config.homebrew.brewPrefix
    ];
  };

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
        args = {appdir = "/Applications";};
        greedy = true;
      }
      "bitcoin-core"
      "bowtie"
      # "delicious-library" # perhaps removed?
      "eagle" # doesn't respect appdir # not available on darwin via Nix
      "google-drive" # doesn't respect appdir
      "powerphotos"
      "psi"
      "r" # doesn't respect appdir
      "racket"
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
      "yousician"
    ];
    enable = true;
    global.brewfile = true;
    masApps = {
      "1Password for Safari" = 1569813296;
      BaseCamp = 411052274; # Garmin, not DHH
      "Blink Lite" = 431473881;
      "Clozure CL" = 489900618;
      Deliveries = 290986013;
      FocusMask = 435999818;
      GarageBand = 682658836;
      iMovie = 408981434;
      Keynote = 409183694;
      Numbers = 409203825;
      Pages = 409201541;
      "Picture Window" = 507262984;
      "Prime Video" = 545519333;
      reMarkable = 1276493162;
      "Remote Mouse" = 403195710;
      ## NB: Evernote has killed Skitch, and it’s subsequently been removed from
      ##     Homebrew (https://github.com/orgs/Homebrew/discussions/6243).
      ##     However, we can still get it from the App store, so do so for now.
      Skitch = 425955336;
      SoundCloud = 412754595;
      Xcode = 497799835;
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
  ## TODO: Build this incrementally from arbitrarily-named scripts.
  system.activationScripts.postActivation.text = ''
    echo "checking for un-managed apps ..."
    installed_packages=$(mktemp --tmpdir installed-packages.XXXXXX)
    ${lib.getExe' pkgs.mas "mas"} list | sort >"$installed_packages"
    echo "App Store apps that are installed, but not in the nix-darwin configuration:"
    join -v1 -1 1 "$installed_packages" - <<EOF
    ${lib.concatStringsSep "\n"
      (lib.sort (a: b: a <= b) (map toString (lib.attrValues config.homebrew.masApps)))}
    EOF
    rm "$installed_packages"

    ## The “default” profile is created by the original Nix install. It can be
    ## dangerous to remove it, and some things reference it explicitly,
    ## unfortunately, so we can at least keep it up to date.
    ##
    ## NB: For this to work, I had to initially replace the original packages in
    ##     the profile with ones from the nixpkgs flake.
    echo "upgrading default nix profile ..."
    sudo nix profile upgrade --all --profile /nix/var/nix/profiles/default

    ## List manual tasks that happen after activating a new configuration.
    echo "Now that a new configuration is activated, there are some steps that need to be"
    echo "performed manually:"
    echo "• enable alacritty & Emacs in Settings → Privacy & Security → App Management"
  '';

  lib.local = {
    ## Converts a NixOS `networking.hosts` value to lines suitable for writing to
    ## /etc/hosts (which is the format required by nix-darwin).
    toHostsFile = hosts:
      lib.concatLines
      (lib.mapAttrsToList
        (ip: domains: ip + " " + lib.concatStringsSep " " domains)
        (lib.filterAttrs (_: v: v != []) hosts));
  };

  programs = {
    bash = {
      enable = true;
      completion.enable = true;
      interactiveShellInit = ''
        # System-wide .bashrc file for interactive bash(1) shells.
        if [ -z "$PS1" ]; then
          return
        fi

        PS1='\h:\W \u\$ '
        # Make bash check its window size after a process completes
        shopt -s checkwinsize

        [ -r "/etc/bashrc_$TERM_PROGRAM" ] && . "/etc/bashrc_$TERM_PROGRAM"
      '';
    };
    zsh = {
      enable = true;
      enableSyntaxHighlighting = true;
      interactiveShellInit = ''
        # Correctly display UTF-8 with combining characters.
        if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
          setopt combiningchars
        fi

        disable log
      '';
      loginShellInit = ''
        # system-wide environment settings for zsh(1)
        if [ -x /usr/libexec/path_helper ]; then
          eval `/usr/libexec/path_helper -s`
        fi
      '';
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  ## TODO: Remove this (from nix-darwin, too) once tailscale/tailscale#8436 is
  ##       fixed.
  services.tailscale.overrideLocalDns = true;

  ## For any of this to work, we need to enable automatic updates in general.
  system.defaults.CustomSystemPreferences."com.apple.SoftwareUpdate".AutomaticCheckEnabled = true;
  ## This will automatically install macOS updates, which we want because Nix
  ## doesn’t manage the OS.
  system.defaults.CustomSystemPreferences."com.apple.commerce".AutoUpdateRestartRequired = true;
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

  system.startup.chime = false;
}
