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
    use-registries = false;
    ## Enable once NixOS/nix#4119 is fixed. This is commented out rather than
    ## set to `false` because the default is `true` on some systems, and we want
    ## to maintain that.
    # sandbox = true;
  };

  outputs = {
    agenix,
    agenix-el,
    bash-strict-mode,
    bitbar-solar-time,
    bradix,
    darwin,
    emacs-color-theme-solarized,
    emacs-extended-faces,
    epresent,
    firefox-darwin,
    flake-parts, # unused, but unifies inputs
    flake-utils,
    flaky,
    home-manager,
    nix-math,
    nixcasks,
    nixpkgs,
    nixpkgs-master,
    nixpkgs-unstable,
    nur,
    org-invoice,
    self,
    systems,
    unison-nix,
  }: let
    stateVersion = "25.05";

    supportedSystems = import systems;

    exampleHomeConfiguration = {
      imports = [self.homeModules.home];

      ## Attributes that the configuration expects to have set, but
      ## aren’t set publicly.
      ##
      ## TODO: Maybe have the configuration check if these are set,
      ##       so it’s more robust.
      accounts.email.accounts.Example = {
        address = "example-user@example.com";
        flavor = "gmail.com";
        primary = true; # This is the important value.
        realName = "example user";
      };
      home.sessionVariables.XDG_RUNTIME_DIR = "/tmp/example/runtime";
      programs.git = {
        extraConfig.github.user = "example-user";
        signing.key = "";
      };
      ## These attributes are simply required by home-manager.
      home = {
        inherit stateVersion;
        homeDirectory = "/tmp/example";
        username = "example-user";
      };
    };
  in
    {
      lib = import ./nix/lib.nix {
        inherit
          agenix
          bitbar-solar-time
          darwin
          emacs-color-theme-solarized
          flaky
          home-manager
          nix-math
          nixcasks
          nixpkgs
          nixpkgs-master
          nixpkgs-unstable
          org-invoice
          self
          ;
      };

      overlays = let
        nixcasks-overlay = final: prev: {
          nixcasks =
            (nixcasks.output {osVersion = "sonoma";})
            .packages
            .${final.system};
        };
      in {
        darwin = nixpkgs.lib.composeManyExtensions [
          nixcasks-overlay
          self.overlays.default
        ];
        ## TODO: Split Emacs into its own overlay.
        default = import ./nix/overlay.nix {
          inherit
            flake-utils
            home-manager
            nixpkgs
            nixpkgs-master
            ;
        };
        home = nixpkgs.lib.composeManyExtensions [
          agenix.overlays.default
          agenix-el.overlays.default
          bash-strict-mode.overlays.default
          bradix.overlays.default
          emacs-extended-faces.overlays.default
          epresent.overlays.default
          (final: prev:
            if prev.stdenv.hostPlatform.isDarwin
            then
              nixpkgs.lib.composeManyExtensions [
                firefox-darwin.overlay
                nixcasks-overlay
              ]
              final
              prev
            else {})
          nur.overlays.default
          unison-nix.overlays.default
          self.overlays.default
        ];
        nixos = nixpkgs.lib.composeManyExtensions [
          agenix.overlays.default
          self.overlays.default
        ];
      };

      darwinModules = {
        darwin = ./nix/modules/darwin/default.nix;
        garnix-cache = ./nix/modules/garnix-cache.nix;
        nix-configuration = ./nix/modules/nix-configuration.nix;
        nixpkgs-configuration = ./nix/modules/nixpkgs-configuration.nix;
      };

      homeModules = {
        emacs = ./nix/modules/emacs;
        garnix-cache = ./nix/modules/garnix-cache.nix;
        home = ./nix/modules/home-configuration.nix;
        i3 = ./nix/modules/i3.nix;
        nix-configuration = ./nix/modules/nix-configuration.nix;
        nixpkgs-configuration = ./nix/modules/nixpkgs-configuration.nix;
        programming = ./nix/modules/programming;
        shell = ./nix/modules/shell;
        ssh = ./nix/modules/ssh.nix;
        tex = ./nix/modules/tex.nix;
        vcs = ./nix/modules/vcs;
      };

      nixosModules = {
        garnix-cache = ./nix/modules/garnix-cache.nix;
        nix-configuration = ./nix/modules/nix-configuration.nix;
        nixos = ./nix/modules/nixos-configuration.nix;
        nixpkgs-configuration = ./nix/modules/nixpkgs-configuration.nix;
      };

      darwinConfigurations = builtins.listToAttrs (map (hostPlatform: {
          name = "${hostPlatform}-example";
          value = self.lib.darwinSystem {
            modules = [
              self.darwinModules.darwin
              {
                home-manager.users.example-user = exampleHomeConfiguration;
                nixpkgs = {inherit hostPlatform;};
                system = {
                  ## This is temporarily required by some options (for example,
                  ## `homebrew.enable`) that were previously applied to the user
                  ## running `darwin-rebuild`.
                  primaryUser = "example-user";
                  stateVersion = 5;
                };
                users.users.example-user.home = "/tmp/example";
              }
            ];
          };
        })
        (builtins.filter (nixpkgs.lib.hasSuffix "-darwin") supportedSystems));

      homeConfigurations = builtins.listToAttrs (map (system: {
          name = "${system}-example";
          value = self.lib.homeManagerConfiguration {
            modules = [exampleHomeConfiguration];
            pkgs = nixpkgs.legacyPackages.${system};
          };
        })
        supportedSystems);

      nixosConfigurations = builtins.listToAttrs (map (hostPlatform: {
          name = "${hostPlatform}-example";
          value = self.lib.nixosSystem {
            modules = [
              self.nixosModules.nixos
              {
                boot.loader.grub.devices = ["/dev/vba"];
                fileSystems."/".device = "/dev/vba";
                home-manager.users.example-user = exampleHomeConfiguration;
                nixpkgs = {inherit hostPlatform;};
                system = {inherit stateVersion;};
                users = {
                  groups.example-user = {};
                  users.example-user = {
                    group = "example-user";
                    home = "/tmp/example";
                    isNormalUser = true;
                  };
                };
              }
            ];
          };
        })
        (builtins.filter (nixpkgs.lib.hasSuffix "-linux") supportedSystems));
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
        flaky.overlays.default
      ];
    in {
      projectConfigurations = flaky.lib.projectConfigurations.nix {
        inherit pkgs self supportedSystems;
        modules = [
          flaky.projectModules.bash
          flaky.projectModules.emacs-lisp
        ];
      };

      devShells =
        {default = flaky.lib.devShells.default system self [] "";}
        // self.projectConfigurations.${system}.devShells;
      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

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

    darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
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

    nix-math = {
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:xddxdd/nix-math";
    };

    nixcasks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:jacekszymanski/nixcasks";
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
