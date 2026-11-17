{
  config,
  flaky,
  homebrew-cleardisk,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    darwinConfig = {
      homebrew.casks = ["cleardisk"];
      nix-homebrew = {
        taps."bysiber/homebrew-cleardisk" = homebrew-cleardisk;
        trust.casks = ["bysiber/cleardisk/cleardisk"];
      };
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

        ## The “default” profile is created by the original Nix install. It can
        ## be dangerous to remove it, and some things reference it explicitly,
        ## unfortunately, so we can at least keep it up to date.
        ##
        ## NOTE: For this to work, I had to initially replace the original
        ##       packages in the profile with ones from the nixpkgs flake.
        echo "upgrading default nix profile ..."
        nix profile upgrade --all --profile /nix/var/nix/profiles/default &>/dev/null
      '';
    };

    homeConfig = {
      home = {
        # Stolen from https://twitter.com/volpegabriel87/status/1585204086240346112
        activation.reportChanges = let
          profiles = "/nix/var/nix/profiles/per-user/${config.home.username}/home-manager-*-link";
        in
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            # Disable nvd if there are less than 2 hm profiles.
            if [ $(ls -d1v ${profiles} 2>/dev/null | wc -l) -lt 2 ]; then
              echo "Skipping changes report..."
            else
              ${pkgs.nvd}/bin/nvd diff $(ls -d1v ${profiles} | tail -2)
            fi
          '';

        packages = [
          ## Make it easy to figure out why derivations are being built.
          ## https://github.com/Gabriella439/nix-diff#readme
          pkgs.nix-diff
          ## Figure out which roots are eating up your disk.
          ## https://github.com/symphorien/nix-du#readme
          pkgs.nix-du
        ];
      };
      services.home-manager = {
        ## This helps keep the size of the Nix store down by periodically expiring
        ## old generations then running `nix-collect-garbage`.
        autoExpire = {
          enable = true;
          frequency = "weekly";
          store.cleanup = true;
        };
        autoUpgrade = {
          enable = pkgs.stdenv.hostPlatform.isLinux;
          frequency = "daily";
        };
      };
    };

    nixosConfig = {};
  };
}
