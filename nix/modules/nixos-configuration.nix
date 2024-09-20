{
  agenix,
  config,
  dotfiles,
  lib,
  pkgs,
  ...
}: {
  imports = [
    agenix.nixosModules.age
    ./input-devices.nix
    ./nix-configuration.nix
    ./nixpkgs-configuration.nix
    ./vcs.nix
  ];

  # TODO: Fix upstream. We shouldn’t need this, but it only has the correct
  #       default if `services.openssh.enable` is `true`, but we use tailscale
  #       instead.
  age.identityPaths =
    map
    (e: e.path)
    (lib.filter
      (e: e.type == "rsa" || e.type == "ed25519")
      config.services.openssh.hostKeys);

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  console.font = "Lat2-Terminus16";

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

  fonts = {
    # Just to have something to fall back on, don’t rely on specific entries.
    enableDefaultPackages = true;
    fontconfig.defaultFonts = {
      monospace = ["Fira Mono"];
      sansSerif = ["Atkinson Hyperlegible"];
    };
    fontDir.enable = true;
    packages = [
      pkgs.atkinson-hyperlegible # https://brailleinstitute.org/freefont
      pkgs.fira
      pkgs.fira-code
      pkgs.fira-code-symbols
      pkgs.fira-mono
      pkgs.inconsolata
    ];
  };

  hardware = {
    bluetooth.enable = true;
    ## `programs.steam.enable` sets this to `true`, but it only works on
    ## x86_64-linux (despite its claim that it works on any 64-bit system).
    opengl.driSupport32Bit = lib.mkForce (pkgs.system == "x86_64-linux");
    pulseaudio.enable = false;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings.LC_TIME = "en_DK.UTF-8"; # Gives us ISO datetimes
    supportedLocales = ["all"]; # How big can these things be?
  };

  ## Auto-adjust system time.
  location.provider = "geoclue2";
  services = {
    automatic-timezoned.enable = true;
    ## To work around NixOS/nixpkgs#68489
    geoclue2.enableDemoAgent = lib.mkForce true;
  };

  networking = {
    # Strict reverse path filtering breaks Tailscale exit node use and some
    # subnet routing setups.
    firewall.checkReversePath = "loose";
    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behavior.
    useDHCP = false;
    wireless.enable = !config.networking.networkmanager.enable;
  };

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

  powerManagement = {
    # cpuFreqGovernor = "ondemand";
    powertop.enable = true;
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    light.enable = true;
    mosh.enable = true;
    # mtr.enable = true;
    steam = {
      enable = pkgs.system != "aarch64-linux";
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  security = {
    pam.services = {
      login.fprintAuth = true;
      xscreensaver.fprintAuth = true;
    };
    rtkit.enable = true;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    blueman.enable = true;

    openssh.enable = false; # subsumed by tailscale

    pipewire = {
      alsa = {
        enable = true;
        support32Bit = true;
      };
      enable = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    printing = {
      browsing = true;
      defaultShared = true;
      enable = true;
    };

    tailscale.enable = true;

    syslogd.enable = true;

    xserver = {
      displayManager.gdm = {
        autoSuspend = false;
        enable = true;
      };
      enable = true;
      windowManager.i3.enable = true;
    };
  };

  ## controlling sleep
  ## See NixOS/nixpkgs#100390
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.login1.suspend" ||
              action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
              action.id == "org.freedesktop.login1.hibernate" ||
              action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
          {
              return polkit.Result.NO;
          }
      });
    '';
  };
  services = {
    logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "ignore";
    };
  };

  sound.enable = true;

  system.autoUpgrade = {
    allowReboot = true;
    enable = true;
  };
}
