{
  description = "Sellout’s general configuration";

  nixConfig = {
    ## NB: This is a consequence of using `self.pkgsLib.runEmptyCommand`, which
    ##     allows us to sandbox derivations that otherwise can’t be.
    allow-import-from-derivation = true;
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = [
      "https://cache.garnix.io"
      "https://sellout.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "sellout.cachix.org-1:v37cTpWBEycnYxSPAgSQ57Wiqd3wjljni2aC0Xry1DE="
    ];
    ## Isolate the build.
    sandbox = "relaxed";
    use-registries = false;
  };

  outputs = inputs: import .config/flake/outputs.nix inputs;

  inputs = {
    ## Flaky should generally be the source of truth for its inputs.
    flaky.url = "github:sellout/flaky";

    bash-strict-mode.follows = "flaky/bash-strict-mode";
    flake-utils.follows = "flaky/flake-utils";
    home-manager.follows = "flaky/home-manager";
    nixpkgs.follows = "flaky/nixpkgs";
    ## NB: i686 isn’t well supported, and I don’t currently have any systems
    ##     using it, so punt on the failures until I need to care.
    systems.url = "github:nix-systems/default";

    agenix = {
      inputs = {
        darwin.follows = "darwin";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
      url = "github:ryantm/agenix";
    };

    agenix-el = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      ## TODO: Switch back to upstream once bash-strict-mode is updated there.
      url = "github:sellout/agenix.el/update-bash-strict-mode";
    };

    bitbar-solar-time = {
      flake = false;
      url = "github:XanderLeaDaren/bitbar-solar-time";
    };

    bradix = {
      inputs.flaky.follows = "flaky";
      url = "github:sellout/bradix";
    };

    brew = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        nix-darwin.follows = "darwin";
        nixpkgs.follows = "nixpkgs";
      };
    };

    darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    };

    emacs-color-theme-solarized = {
      flake = false;
      url = "github:sellout/emacs-color-theme-solarized/correcting-and-realigning";
    };

    emacs-extended-faces = {
      inputs.flaky.follows = "flaky";
      url = "github:sellout/emacs-extended-faces";
    };

    epresent = {
      inputs.flaky.follows = "flaky";
      ## TODO: Remove branch after eschulte/epresent#76 is merged.
      url = "github:sellout/epresent/nix-build";
    };

    firefox-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
    };

    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };

    homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-cask = {
      flake = false;
      url = "github:homebrew/homebrew-cask";
    };

    homebrew-core = {
      flake = false;
      url = "github:homebrew/homebrew-core";
    };

    nix-index-database = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nix-index-database";
    };

    nix-math = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:xddxdd/nix-math";
    };

    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-unstable.follows = "flaky/project-manager/nixpkgs-unstable";

    nur = {
      inputs.flake-parts.follows = "flake-parts";
      url = "github:nix-community/nur";
    };

    org-invoice = {
      flake = false;
      url = "github:sellout/org-invoice";
    };

    unison-nix = {
      inputs = {
        flake-utils.follows = "flake-utils";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:ceedubs/unison-nix";
    };
  };
}
