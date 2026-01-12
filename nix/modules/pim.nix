### Personal information management
###
### PIM isn’t the best-defined category. It definitely includes things like
### address books and calendars. However, if it includes email, does it also
### include all “messaging”? Does it include “office” applications for creating
### personal docs? What about password managers? I don’t have it particularly
### nailed down, so this may shift over time.
###
### See https://en.wikipedia.org/wiki/Personal_information_management
{
  config,
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  imports = [./mozilla.nix];

  config = flaky.lib.multiConfig options {
    darwinConfig = {
      homebrew = {
        casks = [
          ## This is also installed by home.nix#home.packages, but that
          ## _probably_ has even more of the “wrong location” issue mentioned
          ## below, as it’s simply an alias to the Nix store, so keep this
          ## around until I’m willing to fight with that.
          {
            name = "1password";
            ## Doesn’t integrate with browsers properly if moved. Search email
            ## for #PKL-58745-842 for more info.
            args.appdir = "/Applications";
            greedy = true;
          }
          ## NB: in brewCasks, but fails in `copyApps` (see jcszymansk/nixcasks#19)
          "calibre"
        ];
        masApps = {
          "1Password for Safari" = 1569813296;
          Keynote = 409183694; # TODO: migrate to LibreOffice Impress or epresent
          Numbers = 409203825; # TODO: migrate to LibreOffice Calc
          Pages = 409201541; # TODO: migrate to LibreOffice Writer
        };
      };
    };
    homeConfig = let
      devonthink = pkgs.brewCasks.devonthink.overrideAttrs (old: let
        # version I have a license for (and want to migrate off this)
        version = "2.11.3";
      in {
        inherit version;
        src = pkgs.fetchurl {
          url = "https://s3.amazonaws.com/DTWebsiteSupport/download/devonthink/${version}/DEVONthink_Pro_Office.app.zip";
          hash = "sha256-cHSU08cJ4K+kso3dfBOPOr5bHS0gcVt6hitpgqMH9gs=";
        };
        sourceRoot = "DEVONthink Pro.app";
      });

      omnifocus = pkgs.brewCasks.omnifocus.overrideAttrs (old: let
        version = "3.15.8"; # version I have a license for
      in {
        inherit version;
        src = pkgs.fetchurl {
          url = "https://downloads.omnigroup.com/software/macOS/11/OmniFocus-${version}.dmg";
          hash = "sha256-8P578Pr8NdUKI/4NYUuUA7WN6UOXBKLj2T+9xgKqtmE=";
        };
      });
    in {
      accounts = {
        calendar.basePath = "${config.xdg.stateHome}/calendar";
        contact.basePath = "${config.xdg.stateHome}/contact";
        email.maildirBasePath = "${config.xdg.stateHome}/Maildir";
      };

      home.packages =
        []
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          devonthink
          pkgs.brewCasks.fantastical
          ## ostensibly in Nixpkgs, but unpublished
          (config.lib.local.maybeCask "libreoffice" null)
          pkgs.brewCasks.netnewswire
          omnifocus
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs._1password-gui # doesn’t get installed in the correct location on Darwin
          pkgs.calibre # marked broken on darwin
          pkgs.hunspell # needed for spellcheck in libreoffice
          ## TODO: Build lists of these from the configured locales.
          pkgs.hunspellDicts.en_US # needed for spellcheck in libreoffice
          pkgs.hyphenDicts.en_US # needed for hyphenation in libreoffice
        ];

      lib.local = {
        ## Holds the name of the (first) account designated as `primary`, or
        ## `null` (which shouldn’t happen).
        primaryEmailAccountName =
          lib.foldlAttrs
          (acc: key: val:
            if acc == null && val.primary == true
            then key
            else acc)
          null
          config.accounts.email.accounts;

        primaryEmailAccount =
          config.accounts.email.accounts.${config.lib.local.primaryEmailAccountName};

        ## So that dotfiles doesn’t need to know about any specific profiles,
        ## this can be used like
        ##
        ## > programs.thunderbird.profiles.<name> =
        ## >   lib.recursiveUpdate config.lib.local.thunderbird.profileDefaults
        ## >   {…};
        thunderbird.profileDefaults = {
          inherit (config.lib.local.mozilla) search;
          settings =
            config.lib.local.mozilla.settings
            // {
              "calendar.timezone.useSystemTimezone" = true;
              "calendar.view.dayendhour" = 24;
              "calendar.view.daystarthour" = 6;
              "calendar.view.showLocation" = true;
              "calendar.week.start" = 1; # Monday
              "calendar.weeks.inview" = 2;
              "mail.spam.logging.enabled" = true;
              "mail.spam.manualMark" = true;
              "mail.spotlight.enable" = true;
              "privacy.globalprivacycontrol.enabled" = true;
            };
          withExternalGnupg = true;
        };
      };

      local.nixpkgs.allowedUnfreePackages = [
        "1password"
        "1password-cli"
        "onepassword-password-manager"
      ];

      programs.thunderbird.enable = true;

      xdg.configFile."emacs/gnus/.gnus.el".text = ''
        (setq gnus-select-method
              '(nnimap "${config.lib.local.primaryEmailAccount.imap.host}")
              message-send-mail-function 'smtpmail-send-it
              send-mail-function 'smtpmail-send-it
              smtpmail-smtp-server
              "${config.lib.local.primaryEmailAccount.smtp.host}")
      '';
    };
  };
}
