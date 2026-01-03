### Most configuration should be managed per-user via home-manager. This only
### contains things that are provided globally for some reason.
{
  config,
  dotfiles,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../system-configuration.nix
    ./homebrew.nix
  ];

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
    sudo nix profile upgrade --all --profile /nix/var/nix/profiles/default &>/dev/null

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

  nixpkgs.overlays = [dotfiles.overlays.darwin];

  programs = {
    bash = {
      enable = true;
      completion.enable = true;
      ## Copied from /etc/bashrc until I know better.
      interactiveShellInit = lib.readFile ./bashrc;
    };
    zsh = {
      enable = true;
      enableSyntaxHighlighting = true;
      ## Copied from /etc/zshrc until I know better.
      interactiveShellInit = lib.readFile ./zshrc;
      ## Copied from /etc/zprofile until I know better.
      loginShellInit = lib.readFile ./zprofile;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  ## For any of this to work, we need to enable automatic updates in general.
  system.defaults.CustomSystemPreferences."com.apple.SoftwareUpdate".AutomaticCheckEnabled = true;
  ## This will automatically install macOS updates, which we want because Nix
  ## doesn’t manage the OS.
  system.defaults.CustomSystemPreferences."com.apple.commerce".AutoUpdateRestartRequired = true;
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
}
