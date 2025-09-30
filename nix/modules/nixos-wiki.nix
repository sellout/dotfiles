/**
There is an old unofficial NixOS wiki at https://nixos.wiki. For some reason
(perhaps explained by NixOS/nixos-wiki-infra#124), it doesn’t acknowledge the
existence of the official wiki at all (despite [the apparent repo for the
unofficial wiki](https://github.com/nix-community/wiki) pointing to the official
wiki).

This module includes various approaches to help ensure we end up at the official
 wiki most of the time.
*/
{
  config,
  flaky,
  lib,
  options,
  pkgs,
  ...
}: let
  ## https://nixos.wiki currently resolves to the below IP. Thankfully the
  ## paths are the same for the old and new wikis, so we can simply redirect
  ## the domain name.
  hosts."104.26.14.206" = ["wiki.nixos.org"];
in {
  config = flaky.lib.multiConfig options {
    darwinConfig.environment.etc.hosts.text =
      config.lib.local.toHostsFile hosts;
    homeConfig = {
      ## TODO: Take a list of profiles as an argument.
      programs.firefox.profiles.default = {
        ## FIXME: We can only do this if we let Home Manager overwrite _all_ our
        ##        Firefox extension settings, so make sure we have them all
        ##        migrated before enabling this block.
        ##
        ## There is a Firefox add-on,
        ## [Redirector](https://addons.mozilla.org/en-US/firefox/addon/redirector/)
        ## that will map URLs for us, so we enable it for old wiki URLS.
        # extensions = {
        #   packages = [pkgs.nur.repos.rycee.firefox-addons.redirector];
        #   settings."redirector@einaregilsson.com" = {
        #     force = true;
        #     settings.redirects = [
        #       ## Stolen from
        #       ## https://gist.github.com/lorenzleutgeb/4e78dd33594039bffbe1460fbe00b0d1
        #       {
        #         description = "NixOS Wiki";
        #         exampleUrl = "http://nixos.wiki/wiki/Main_Page";
        #         exampleResult = "http://wiki.nixos.org/wiki/Main_Page";
        #         error = null;
        #         includePattern = "http(s?)://nixos.wiki/wiki/(.*)";
        #         excludePattern = "";
        #         patternDesc = "";
        #         redirectUrl = "http$1://wiki.nixos.org/wiki/$2";
        #         patternType = "R";
        #         processMatches = "noProcessing";
        #         disabled = false;
        #         grouped = false;
        #         appliesTo = ["main_frame"];
        #       }
        #     ];
        #   };
        # };
        ## We can add the official NixOS wiki as a Firefox search extension,
        ## giving us a way to directly access the correct one.
        search.engines.nixos-wiki = {
          name = "NixOS Wiki";
          urls = [
            {
              template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
            }
          ];
          iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
          definedAliases = ["@nw"];
        };
      };
    };
    nixosConfig.networking = {inherit hosts;};
  };
}
