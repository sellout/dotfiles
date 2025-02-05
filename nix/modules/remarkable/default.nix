## reMarkable (https://remarkable.com/) is a company that makes a number of
## tablets. This module is for interacting with those tablets from a computer.
{
  config,
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    darwinConfig.homebrew.masApps.reMarkable = 1276493162;
    homeConfig.home = {
      ## https://github.com/juruen/rmapi/blob/master/docs/tutorial-print-macosx.md
      file = lib.mkIf pkgs.stdenv.isDarwin {
        "Library/PDF Services/Save PDF to reMarkable.workflow" = {
          ## We include one of the files separately, because it needs
          ## substitutions.
          recursive = true;
          source = ./save-pdf-to-remarkable.workflow;
        };
        "Library/PDF Services/Save PDF to reMarkable.workflow/Contents/document.wflow".source = pkgs.substituteAll {
          src = ./save-pdf-to-remarkable.wflow;
          inherit (pkgs) rmapi;
        };
      };
      packages = [
        ## a CLI for reMarkable – `rmapi` needs to be run manually once after
        ## installation to set up the connection to your reMarkable account.
        pkgs.rmapi
      ];
      ## This is the default on Linux anyway, but it uses
      ## ~/Library/Application Support on macOS, so this makes it consistent.
      sessionVariables.RMAPI_CONFIG = "${config.xdg.configHome}/rmapi/rmapi.conf";
    };
  };
}
