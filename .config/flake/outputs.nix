{
  agenix,
  agenix-el,
  bash-strict-mode,
  bitbar-solar-time,
  bradix,
  brew,
  darwin,
  emacs-color-theme-solarized,
  emacs-extended-faces,
  epresent,
  firefox-darwin,
  flake-parts, # unused, but unifies inputs
  flake-utils,
  flaky,
  home-manager,
  homebrew,
  homebrew-cask,
  homebrew-core,
  nix-index-database,
  nix-math,
  nixpkgs,
  nixpkgs-master,
  nixpkgs-unstable,
  nur,
  org-invoice,
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
      settings.github.user = "example-user";
      signing.key = "";
    };
    ## These attributes are simply required by home-manager.
    home = {
      stateVersion = "25.11";
      homeDirectory = "/tmp/example";
      username = "example-user";
    };
  };
in
  {
    lib = import ../../nix/lib.nix {
      inherit
        agenix
        bitbar-solar-time
        brew
        darwin
        emacs-color-theme-solarized
        flaky
        home-manager
        homebrew
        homebrew-cask
        homebrew-core
        nix-index-database
        nix-math
        nixpkgs
        nixpkgs-master
        nixpkgs-unstable
        org-invoice
        self
        ;
    };

    overlays = {
      darwin = self.overlays.default;
      ## TODO: Split Emacs into its own overlay.
      default = import ../../nix/overlay.nix {
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
              brew.overlays.default
              firefox-darwin.overlay
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
      darwin = ../../nix/modules/darwin/default.nix;
      garnix-cache = ../../nix/modules/garnix-cache.nix;
      nix-configuration = ../../nix/modules/nix-configuration.nix;
      nixpkgs-configuration = ../../nix/modules/nixpkgs-configuration.nix;
    };

    homeModules = {
      emacs = ../../nix/modules/emacs;
      garnix-cache = ../../nix/modules/garnix-cache.nix;
      home = ../../nix/modules/home-configuration.nix;
      i3 = ../../nix/modules/i3.nix;
      nix-configuration = ../../nix/modules/nix-configuration.nix;
      nixpkgs-configuration = ../../nix/modules/nixpkgs-configuration.nix;
      programming = ../../nix/modules/programming;
      shell = ../../nix/modules/shell;
      ssh = ../../nix/modules/ssh.nix;
      tex = ../../nix/modules/tex.nix;
      vcs = ../../nix/modules/vcs;
    };

    nixosModules = {
      garnix-cache = ../../nix/modules/garnix-cache.nix;
      nix-configuration = ../../nix/modules/nix-configuration.nix;
      nixos = ../../nix/modules/nixos-configuration.nix;
      nixpkgs-configuration = ../../nix/modules/nixpkgs-configuration.nix;
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
                stateVersion = 6;
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
              system.stateVersion = "25.11";
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
      self.projectConfigurations.${system}.devShells
      // {default = flaky.lib.devShells.default system self [] "";};

    checks = self.projectConfigurations.${system}.checks;
    formatter = self.projectConfigurations.${system}.formatter;
  })
