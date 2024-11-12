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
    ./games.nix
    ./input-devices.nix
    ./locale.nix
    ./nix-configuration.nix
    ./nixpkgs-configuration.nix
    ./vcs
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
      sansSerif = ["Lexica Ultralegible"];
    };
    fontDir.enable = true;
    packages = [
      pkgs.fira
      pkgs.fira-code
      pkgs.fira-code-symbols
      pkgs.fira-mono
      pkgs.inconsolata
      pkgs.lexica-ultralegible
    ];
  };

  hardware = {
    bluetooth.enable = true;
    pulseaudio.enable = false;
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
      ## Mitigate various CUPS vulnerabilities (see
      ## https://www.evilsocket.net/2024/09/26/Attacking-UNIX-systems-via-CUPS-Part-I/)
      enable = false;
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
    };

    printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
      ## This might also help mitigate the above-mentioned vulnerabilities,
      ## since printing isn’t enabled all the time.
      startWhenNeeded = true;
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
