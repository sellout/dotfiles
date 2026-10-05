{
  config,
  lib,
  pkgs,
  ...
}: let
  ## These are defined in https://mozilla.github.io/policy-templates/.
  policies = {
    DisableAppUpdate = true;
    # See https://mastodon.social/@mcc/114869357468477091
    DisableFirefoxStudies = true;
  };
in {
  imports = [./mozilla.nix];

  ## So that dotfiles doesn’t need to know about any specific profiles,
  ## this can be used like
  ##
  ## > programs.firefox.profiles.<name> =
  ## >   lib.recursiveUpdate config.lib.local.firefox.profileDefaults {…};
  lib.local.firefox.profileDefaults = {
    inherit (config.lib.local.mozilla) search;
    ## These are ordered to match `about:addons`.
    extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
      bitwarden
      onepassword-password-manager
      # Add to MyRegistry.com Button
      # Add to OmniFocus
      # BibItNow! # creates BibTeX citations
      c-c-search-extension # prefix search bar with `cc ` to search C/C++ docs
      # Clip to DEVONthink (managed by DEVONthink)
      display-_anchors
      # Evernote Web Clipper
      facebook-container
      multi-account-containers
      ghostery
      # Honey
      # Panorama Tab Groups
      # Read on reMarkable
      rust-search-extension # prefix search bar with `rs ` to search Rust docs
      # Tab Manager Plus for Firefox
      to-google-translate
      tree-style-tab
      user-agent-string-switcher
      # Window Titler
      # ZenHub for GitHub
      ## Disabled
      foxytab
    ];
    ## You can explore the settings at the URL `about:config` in Firefox.
    settings =
      config.lib.local.mozilla.settings
      // {
        "browser.aboutConfig.showWarning" = false;
        "browser.display.use_system_colors" = true;
        "browser.contentblocking.category" = "strict";
        "browser.uidensity" = 1; # compact
        ## new tab page
        "browser.newtabpage.activity-stream.feeds.section.highlights" = true;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.hideLogo" = true;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.widgets.weather.enabled" = false;
        "browser.newtabpage.pinned" = [
          {
            label = "Dagny";
            url = "https://dagny.co/";
          }
          {
            label = "Home Assistant";
            url = "http://100.124.17.149:8123";
          }
          {
            label = "NeoDB";
            url = "https://neodb.social/";
          }
          {
            label = "Home Manager configuration";
            url = "https://nix-community.github.io/home-manager/options/home-manager";
          }
          {
            label = "NixOS configuration";
            url = "https://nixos.org/manual/nixos/stable/options.html";
          }
          {
            label = "nix-darwin configuration";
            url = "https://nix-darwin.github.io/nix-darwin/manual";
          }
        ];
        ## disable AI features
        ##
        ## - https://buc.ci/abucci/p/1763845084.289082
        ## - https://www.shigjeta.net/how-to-kill-every-ai-feature-in-firefox-for-good/
        "browser.ai.control.default" = "blocked";
        "browser.ai.control.linkPreviewKeyPoints" = "blocked";
        "browser.ai.control.pdfjsAltText" = "blocked";
        "browser.ai.control.sidebarChatbot" = "blocked";
        "browser.ai.control.smartTabGroups" = "blocked";
        "browser.ai.control.smartWindow" = "blocked";
        "browser.ai.control.speechRecognition" = "blocked";
        "browser.ai.control.translations" = "blocked";
        "browser.aiwindow.enabled" = false;
        "browser.ml.chat.enabled" = false;
        "browser.ml.chat.menu" = false;
        "browser.ml.chat.page" = false;
        "browser.ml.chat.page.footerBadge" = false;
        "browser.ml.chat.page.menuBadge" = false;
        "browser.ml.chat.shortcuts" = false;
        "browser.ml.chat.shortcuts.custom" = false;
        "browser.ml.chat.sidebar" = false;
        ## NB: This might be the only one that’s required.
        "browser.ml.enable" = false;
        "browser.ml.linkPreview.enabled" = false;
        "browser.ml.pageAssist.enabled" = false;
        "browser.ml.smartAssist.enabled" = false;
        "browser.search.visualSearch.featureGate" = false;
        "browser.tabs.groups.smart.enabled" = false;
        "browser.tabs.groups.smart.optin" = false;
        "browser.tabs.groups.smart.userEnabled" = false;
        "browser.urlbar.quicksuggest.mlEnabled" = false;
        "extensions.ml.enabled" = false;
        "pdfjs.enableAltText" = false;
        "pdfjs.enableAltTextModelDownload" = false;
        "pdfjs.enableGuessAltText" = false;
        "places.semanticHistory.featureGate" = false;
        "sidebar.notification.badge.aichat" = false;
        ## Disable ads for Mozilla products
        "browser.preferences.moreFromMozilla" = false;
        "browser.startup.homepage" = "https://github.com/pulls/review-requested";
        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        ## Automatically enable newly-installed extensions.
        "extensions.autoDisableScopes" = 0;
        ## printing
        "print.prefer_system_dialog" = true;
        ## privacy
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.globalprivacycontrol.functionality.enabled" = true;
        "privacy.globalprivacycontrol.pbmode.enabled" = true;
        ## Mozilla Sync account
        "services.sync.username" =
          config.lib.local.primaryEmailAccount.address;
      };
    userChrome = ''
      /* Hide tab bar in FF Quantum */
      @-moz-document url("chrome://browser/content/browser.xul") {
        #TabsToolbar {
          visibility: collapse !important;
          margin-bottom: 21px !important;
        }

        #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
          visibility: collapse !important;
        }
      }
    '';
  };

  programs.firefox = {
    inherit policies;

    enable = pkgs.stdenv.hostPlatform.system != "aarch64-linux";
  };

  targets.darwin.defaults."org.mozilla.firefox" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    policies
    // {
      ## Allows `programs.firefox.policies` to work on darwin. See
      ## https://gist.github.com/todgru/025eee8c19ae9bc21c1f53bc7abe1fd4
      EnterprisePoliciesEnabled = true;
    }
  );
}
