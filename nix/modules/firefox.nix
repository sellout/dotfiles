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
  programs.firefox = {
    inherit policies;

    enable = pkgs.stdenv.hostPlatform.system != "aarch64-linux";
    profiles.default = {
      ## These are ordered to match `about:addons`.
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
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
      search = {
        default = "ddg";
        engines = {
          nix-packages = {
            name = "Nix Packages";
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };

          amazon.metaData.alias = "@amazon";
          bing.metaData.hidden = true;
          ebay.metaData.hidden = true;
          google.metaData = {
            alias = "@google";
            hidden = true;
          };
          wikipedia.metaData.alias = "@wikipedia";
        };
        force = true;
        order = ["ddg" "wikipedia" "nw" "np" "amazon"];
      };
      ## You can explore the settings at the URL `about:config` in Firefox.
      settings = let
        defaultFont = config.lib.local.defaultFont;
      in {
        "browser.aboutConfig.showWarning" = false;
        "browser.display.use_system_colors" = true;
        "browser.contentblocking.category" = "strict";
        ## Disable AI features
        "browser.ml.chat.enabled" = false;
        "browser.ml.chat.shortcuts" = false;
        "browser.ml.chat.shortcuts.custom" = false;
        "browser.ml.chat.sidebar" = false;
        "browser.ml.enable" = false;
        "browser.tabs.groups.smart.enabled" = false;
        "browser.tabs.groups.smart.optin" = false;
        "browser.tabs.groups.smart.userEnabled" = false;
        ## Disable ads for Mozilla products
        "browser.preferences.moreFromMozilla" = false;
        "browser.startup.homepage" = "https://github.com/pulls/review-requested";
        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        ## Automatically enable newly-installed extensions.
        "extensions.autoDisableScopes" = 0;
        ## fonts
        "font.default.x-unicode" = "sans-serif";
        "font.default.x-western" = "sans-serif";
        "font.name.monospace.x-unicode" = defaultFont.monoFamily;
        "font.name.monospace.x-western" = defaultFont.monoFamily;
        "font.name.sans-serif.x-unicode" = defaultFont.string;
        "font.name.sans-serif.x-western" = defaultFont.string;
        "font.size.monospace.x-unicode" = builtins.floor defaultFont.size;
        "font.size.monospace.x-western" = defaultFont.size;
        "font.size.variable.x-unicode" = defaultFont.size;
        "font.size.variable.x-western" = builtins.floor defaultFont.size;
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
