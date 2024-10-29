{
  description = "Sellout’s general configuration";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
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
    bradix,
    darwin,
    emacs-color-theme-solarized,
    emacs-extended-faces,
    epresent,
    firefox-darwin,
    flake-utils,
    flaky,
    home-manager,
    mkalias,
    nixcasks,
    nixpkgs,
    nur,
    org-invoice-table,
    self,
    systems,
    unison-nix,
  }: let
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
        homeDirectory = "/tmp/example";
        stateVersion = "24.05";
        username = "example-user";
      };
    };
  in
    {
      lib = import ./nix/lib.nix {
        inherit
          agenix
          darwin
          emacs-color-theme-solarized
          flaky
          home-manager
          nixpkgs
          org-invoice-table
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
            mkalias
            nixpkgs
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
          nur.overlay
          ## TODO: unison-nix’s UCM doesn’t yet support aarch64-darwin, so we
          ##       use the rest of the overlay without shadowing the UCM from
          ##       Nixpkgs.
          (final: prev:
            nixpkgs.lib.removeAttrs
            (unison-nix.overlays.default final prev)
            ["unison-ucm"])
          self.overlays.default
        ];
        nixos = nixpkgs.lib.composeManyExtensions [
          agenix.overlays.default
          self.overlays.default
        ];
      };

      darwinModules = {
        darwin = import ./nix/modules/darwin-configuration.nix;
        nix-configuration = import ./nix/modules/nix-configuration.nix;
        nixpkgs-configuration = import ./nix/modules/nixpkgs-configuration.nix;
      };

      homeModules = {
        emacs = import ./nix/modules/emacs;
        home = import ./nix/modules/home-configuration.nix;
        i3 = import ./nix/modules/i3.nix;
        nix-configuration = import ./nix/modules/nix-configuration.nix;
        nixpkgs-configuration = import ./nix/modules/nixpkgs-configuration.nix;
        shell = import ./nix/modules/shell.nix;
        tex = import ./nix/modules/tex.nix;
        vcs = import ./nix/modules/vcs.nix;
      };

      nixosModules = {
        nix-configuration = import ./nix/modules/nix-configuration.nix;
        nixos = import ./nix/modules/nixos-configuration.nix;
        nixpkgs-configuration = import ./nix/modules/nixpkgs-configuration.nix;
      };

      darwinConfigurations = let
        ## Generates two darwinConfigurations – one using the home-manager
        ## module, and one without.
        ##
        ## TODO: This exists so the one without can be tested on garnix (in a
        ##       sandbox) until NixOS/nix#4119 is fixed.
        generate = homeManagerModule: hostPlatform: {
          name =
            "${hostPlatform}-example"
            + (
              if homeManagerModule == {}
              then "-bare"
              else ""
            );
          value = self.lib.darwinSystem {
            modules = [
              self.darwinModules.darwin
              {
                nixpkgs = {inherit hostPlatform;};
                system.stateVersion = 5;
                users.users.example-user.home = "/tmp/example";
              }
              homeManagerModule
            ];
          };
        };
      in
        builtins.listToAttrs (nixpkgs.lib.concatMap (hostPlatform: [
            (generate {} hostPlatform)
            (generate
              {home-manager.users.example-user = exampleHomeConfiguration;}
              hostPlatform)
          ])
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
                system.stateVersion = "24.05";
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
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      projectConfigurations = flaky.lib.projectConfigurations.default {
        inherit pkgs self supportedSystems;
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
      };
      url = "github:ryantm/agenix";
    };

    agenix-el = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:t4ccer/agenix.el";
    };

    bradix = {
      inputs.flaky.follows = "flaky";
      url = "github:sellout/bradix";
    };

    darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:LnL7/nix-darwin";
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

    ## Avoids the need to give `Finder` access to make aliases on MacOS.
    mkalias = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:reckenrode/mkalias";
    };

    nixcasks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:jacekszymanski/nixcasks";
    };

    ## NB: These are very helpful when they’re needed, but otherwise keep them
    ##     commented out, because they’re big and slow.
    # nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nur.url = "github:nix-community/nur";

    org-invoice-table = {
      flake = false;
      url = "git+https://git.sr.ht/~trevdev/org-invoice-table";
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
