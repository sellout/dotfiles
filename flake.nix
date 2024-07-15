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
    registries = false;
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
    self,
    unison,
  } @ inputs: let
    ## NB: i686 isn’t well supported, and I don’t currently have any systems
    ##     using it, so punt on the failures until I need to care.
    supportedSystems =
      nixpkgs.lib.remove
      flake-utils.lib.system.i686-linux
      flaky.lib.defaultSystems;

    nixpkgsConfig = {
      allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "1password"
          "1password-cli"
          "eagle"
          "onepassword-password-manager"
          "plexmediaserver"
          "steam"
          "steam-original"
          "steam-run"
          "vscode-extension-ms-vsliveshare-vsliveshare"
          "zoom"
        ];
    };
  in
    {
      overlays = {
        darwin = nixpkgs.lib.composeManyExtensions [
          self.overlays.default
        ];
        ## TODO: Split Emacs into its own overlay.
        default = import ./nix/overlay.nix {
          inherit flake-utils home-manager mkalias nixpkgs nixpkgsConfig unison;
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
              firefox-darwin.overlay final prev
              // {nixcasks = nixcasks.legacyPackages.${final.system};}
            else {})
          nur.overlay
          unison.overlays.default
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
      };

      homeModules = {
        emacs = import ./nix/modules/emacs;
        home = import ./nix/modules/home-configuration.nix;
        i3 = import ./nix/modules/i3.nix;
        nix-configuration = import ./nix/modules/nix-configuration.nix;
        shell = import ./nix/modules/shell.nix;
      };

      nixosModules = {
        nix-configuration = import ./nix/modules/nix-configuration.nix;
        nixos = import ./nix/modules/nixos-configuration.nix;
      };

      darwinConfigurations =
        builtins.listToAttrs
        (builtins.map
          (system: {
            name = "${system}-example";
            value = darwin.lib.darwinSystem {
              pkgs = import nixpkgs {
                inherit system;
                config = nixpkgsConfig;
                overlays = [self.overlays.darwin];
              };
              specialArgs = {inherit inputs;};
              modules = [self.darwinModules.darwin];
            };
          })
          (builtins.filter (nixpkgs.lib.hasSuffix "darwin") supportedSystems));

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (system: {
            name = "${system}-example";
            value = home-manager.lib.homeManagerConfiguration {
              pkgs = import nixpkgs {
                inherit system;
                config = nixpkgsConfig;
                overlays = [self.overlays.home];
              };
              extraSpecialArgs = {inherit inputs;};
              modules = [
                self.homeModules.home
                {
                  ## Attributes that the configuration expects to have set, but
                  ## aren’t set publicly.
                  ##
                  ## TODO: Maybe have the configuration check if these are set,
                  ##       so it’s more robust.
                  accounts.email.accounts.Example = {
                    address = "example-user@example.com";
                    flavor = "gmail.com";
                    primary = true;
                    realName = "example user";
                  };
                  programs.git = {
                    extraConfig.github.user = "example-user";
                    signing.key = "";
                  };
                  ## These attributes are simply required by home-manager.
                  home = {
                    homeDirectory = "/tmp/example";
                    username = "example-user";
                  };
                }
              ];
            };
          })
          supportedSystems);

      nixosConfigurations =
        builtins.listToAttrs
        (builtins.map
          (system: {
            name = "${system}-example";
            value = nixpkgs.lib.nixosSystem {
              pkgs = import nixpkgs {
                inherit system;
                config = nixpkgsConfig;
                overlays = [self.overlays.nixos];
              };
              specialArgs = {inherit inputs;};
              modules = [
                agenix.nixosModules.age
                self.nixosModules.nixos
                {
                  fileSystems."/".device = "/dev/vba";
                }
              ];
            };
          })
          (builtins.filter (nixpkgs.lib.hasSuffix "linux") supportedSystems));
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {inherit system;};
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
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:t4ccer/agenix.el";
    };

    bash-strict-mode = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bash-strict-mode";
    };

    bradix = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bradix";
    };

    darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:lnl7/nix-darwin";
    };

    emacs-color-theme-solarized = {
      flake = false;
      url = "github:sellout/emacs-color-theme-solarized/correcting-and-realigning";
    };

    emacs-extended-faces = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/emacs-extended-faces";
    };

    epresent = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      ## TODO: Remove branch after eschulte/epresent#76 is merged.
      url = "github:sellout/epresent/nix-build";
    };

    firefox-darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flake-utils.follows = "flake-utils";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-23.11";
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

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    ## NB: These are very helpful when they’re needed, but otherwise keep them
    ##     commented out, because they’re big and slow.
    # nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nur.url = "github:nix-community/nur";

    unison = {
      inputs = {
        flake-utils.follows = "flake-utils";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:ceedubs/unison-nix";
    };
  };
}
