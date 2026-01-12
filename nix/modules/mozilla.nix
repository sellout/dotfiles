### Configuration shared by Mozilla applications (namely Firefox and
### Thunderbird).
{
  config,
  pkgs,
  ...
}: {
  ## This same structure is shared by both Firefox and Thunderbird.
  lib.local.mozilla = let
    defaultFont = config.lib.local.defaultFont;
  in {
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
    ## You can explore the settings at the URL `about:config` in Firefox. It‘s a
    ## bit harder to find them for Thunderbird.
    settings = {
      "font.default.x-unicode" = "sans-serif";
      "font.default.x-western" = "sans-serif";
      "font.name.monospace.x-unicode" = defaultFont.monoFamily;
      "font.name.monospace.x-western" = defaultFont.monoFamily;
      "font.name.sans-serif.x-unicode" = defaultFont.sansFamily;
      "font.name.sans-serif.x-western" = defaultFont.sansFamily;
      "font.name.serif.x-unicode" = defaultFont.serifFamily;
      "font.name.serif.x-western" = defaultFont.serifFamily;
      "font.size.monospace.x-unicode" = builtins.floor defaultFont.size;
      "font.size.monospace.x-western" = builtins.floor defaultFont.size;
      "font.size.variable.x-unicode" = builtins.floor defaultFont.size;
      "font.size.variable.x-western" = builtins.floor defaultFont.size;
    };
  };
}
