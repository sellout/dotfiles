## Ntfy – CLI notfication sender – https://ntfy.readthedocs.io/en/
{
  lib,
  pkgs,
  ...
}: let
  initExtra = ''
    eval "$(ntfy shell-integration --foreground-too --longer-than 2)"
  '';
in {
  home = {
    packages = [pkgs.ntfy];
    sessionVariables.AUTO_NTFY_DONE_IGNORE = lib.concatStringsSep " " [
      "emacs"
      "less"
      "man"
      "ssh"
    ];
  };

  nixpkgs = {
    ## TODO: This is needed by the overlaid version of `pkgs.ntfy`, because I
    ##       can’t figure out how to override django properly.
    config.permittedInsecurePackages = ["python3.12-django-3.2.25"];
    overlays = [
      (final: prev: {
        ## TODO: Update this upstream. I’ve changed it to work with the python3
        ##       in Nixpkgs 24.05. There were multiple issues
        ##    1. ipython doesn’t work with python39;
        ##    2. ntfy doesn’t compile with python 3.11 (the default python3 in
        ##       Nixpkgs 24.05), but ntfy’s master branch does; and
        ##    3. the depended-on version of django is insecure and I can’t
        ##       figure out how to override it.
        ntfy =
          (prev.ntfy.override {
            python39 = final.python3;
            withXmpp = false; # sleekxmpp doesn’t work on Python 3.12
          })
          .overrideAttrs (old: {
            version = "2.7.1";

            src = final.fetchFromGitHub {
              owner = "dschep";
              repo = "ntfy";
              rev = "398014eee761082ec15f8d7ab0433ee73ee7f734";
              hash = "sha256-SokLgzH2UgtQaSo+P2xDT2OI7/Bcl+yMd3zlvFrK4Og=";
            };

            ## NB: The patches applied upstream are merged now.
            patches = [
              ## Get it working with Python 3.11 & 3.12.
              (final.fetchpatch {
                name = "ntfy-python311.patch";
                url = "https://github.com/dschep/ntfy/pull/271.patch";
                hash = "sha256-ua+d04h9EiwosZtPaJXxiXWp6KLuuaI5XUPf2BOmPng=";
              })
            ];

            ## Pip isn’t in scope in the upstream derivation.
            doInstallCheck = false;
          });
      })
    ];
  };

  programs = {
    bash = {inherit initExtra;};
    zsh = {inherit initExtra;};
  };
}
