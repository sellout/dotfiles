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

  outputs = inputs: let
    pname = "dotfiles";

    nixpkgsConfig = {
      allowUnfreePredicate = pkg:
        builtins.elem (inputs.nixpkgs.lib.getName pkg) [
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
        darwin = inputs.nixpkgs.lib.composeManyExtensions [
          inputs.self.overlays.default
        ];
        ## TODO: Split Emacs into its own overlay.
        default = import ./nix/overlay.nix {
          inherit
            (inputs)
            emacs-color-theme-solarized
            flake-utils
            mkalias
            nixpkgs
            nixpkgs-master
            ;
          inherit nixpkgsConfig;
        };
        home = inputs.nixpkgs.lib.composeManyExtensions [
          inputs.agenix.overlays.default
          inputs.agenix-el.overlays.default
          inputs.bash-strict-mode.overlays.default
          inputs.bradix.overlays.default
          inputs.emacs-extended-faces.overlays.default
          inputs.epresent.overlays.default
          (final: prev:
            if prev.stdenv.hostPlatform.isDarwin
            then
              inputs.firefox-darwin.overlay final prev
              // {nixcasks = inputs.nixcasks.legacyPackages.${final.system};}
            else {})
          inputs.nur.overlay
          inputs.self.overlays.default
        ];
        nixos = inputs.nixpkgs.lib.composeManyExtensions [
          inputs.agenix.overlays.default
          inputs.self.overlays.default
        ];
      };

      darwinModules = {
        darwin = import ./nix/modules/darwin-configuration.nix;
        nix-configuration = import ./nix/modules/nix-configuration.nix;
      };

      homeModules = {
        emacs = import ./nix/modules/emacs.nix;
        home = import ./nix/modules/home-configuration.nix;
        i3 = import ./nix/modules/i3.nix;
        nix-configuration = import ./nix/modules/nix-configuration.nix;
        shell = import ./nix/modules/shell.nix;
      };

      nixosModules = {
        nix-configuration = import ./nix/modules/nix-configuration.nix;
        nixos = import ./nix/modules/nixos-configuration.nix;
      };

      darwinConfigurations = let
        name = "${pname}-example";
      in
        builtins.listToAttrs
        (builtins.map
          (system: {
            name = "${system}-${name}";
            value = inputs.darwin.lib.darwinSystem {
              pkgs = import inputs.nixpkgs {
                inherit system;
                config = nixpkgsConfig;
                overlays = [inputs.self.overlays.darwin];
              };
              modules = [inputs.self.darwinModules.darwin];
            };
          })
          [
            inputs.flake-utils.lib.system.aarch64-darwin
            inputs.flake-utils.lib.system.x86_64-darwin
          ]);

      homeConfigurations = let
        name = "${pname}-example";
      in
        builtins.listToAttrs
        (builtins.map
          (system: {
            name = "${system}-${name}";
            value = inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                inherit system;
                config = nixpkgsConfig;
                overlays = [inputs.self.overlays.home];
              };
              modules = [
                inputs.self.homeModules.home
                {
                  ## Attributes that the configuration expects to have set, but
                  ## aren’t set publicly.
                  ##
                  ## TODO: Maybe have the configuration check if these are set,
                  ##       so it’s more robust.
                  accounts.email.accounts.Example = {
                    address = "${name}-user@example.com";
                    flavor = "gmail.com";
                    primary = true;
                    realName = "${name} user";
                  };
                  programs.git = {
                    extraConfig.github.user = "${name}-user";
                    signing.key = "";
                  };
                  ## These attributes are simply required by home-manager.
                  home = {
                    homeDirectory = "/tmp/${name}";
                    username = "${name}-user";
                  };
                }
              ];
            };
          })
          inputs.flaky.lib.defaultSystems);

      nixosConfigurations = let
        name = "${pname}-example";
      in
        builtins.listToAttrs
        (builtins.map
          (system: {
            name = "${system}-${name}";
            value = inputs.nixpkgs.lib.nixosSystem {
              pkgs = import inputs.nixpkgs {
                inherit system;
                config = nixpkgsConfig;
                overlays = [inputs.self.overlays.nixos];
              };
              modules = [
                inputs.agenix.nixosModules.age
                inputs.self.nixosModules.nixos
                {
                  fileSystems."/".device = "/dev/vba";
                }
              ];
            };
          })
          [
            # inputs.flake-utils.lib.system.aarch64-linux
            inputs.flake-utils.lib.system.x86_64-linux
          ]);
    }
    // inputs.flake-utils.lib.eachSystem inputs.flaky.lib.defaultSystems (system: let
      pkgs = import inputs.nixpkgs {inherit system;};
    in {
      projectConfigurations = inputs.flaky.lib.projectConfigurations.default {
        inherit pkgs;
        inherit (inputs) self;
      };

      devShells =
        {default = inputs.flaky.lib.devShells.default system inputs.self [] "";}
        // inputs.self.projectConfigurations.${system}.devShells;
      checks = inputs.self.projectConfigurations.${system}.checks;
      formatter = inputs.self.projectConfigurations.${system}.formatter;
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
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nur.url = "github:nix-community/nur";
  };
}
