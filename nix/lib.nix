{
  agenix,
  bitbar-solar-time,
  brew,
  darwin,
  emacs-color-theme-solarized,
  flaky,
  home-manager,
  nix-index-database,
  nix-math,
  nixpkgs,
  nixpkgs-master,
  nixpkgs-unstable,
  org-invoice,
  self,
}: let
  math = nix-math.lib.math;

  ## Recursively merges a list of values.
  ##
  ## NB: Stolen from https://stackoverflow.com/a/54505212
  recursiveMerge = attrList: let
    f = attrPath:
      nixpkgs.lib.zipAttrsWith (
        n: values:
          if nixpkgs.lib.tail values == []
          then nixpkgs.lib.head values
          else if nixpkgs.lib.all nixpkgs.lib.isList values
          then nixpkgs.lib.unique (nixpkgs.lib.concatLists values)
          else if nixpkgs.lib.all nixpkgs.lib.isAttrs values
          then f (attrPath ++ [n]) values
          else nixpkgs.lib.last values
      );
  in
    f [] attrList;

  ## For Home Manager configurations (both standalone and as a system module).
  extraSpecialArgs = {
    inherit
      agenix
      bitbar-solar-time
      brew
      emacs-color-theme-solarized
      flaky
      math
      nixpkgs
      nixpkgs-master
      nixpkgs-unstable
      org-invoice
      ;
    dotfiles = self;
  };

  ## Modules to be provided to every Home Manager user on every system.
  sharedModules = [nix-index-database.homeModules.nix-index];
in {
  ## Just like upstream `darwinSystem`, but adds all of the `specialArgs`
  ## required by the configuration in this repo (and the `extraSpecialArgs`
  ## required by the Home Manager configuration).
  darwinSystem = attrs:
    darwin.lib.darwinSystem (recursiveMerge [
      {
        modules = [
          home-manager.darwinModules.default
          {home-manager = {inherit extraSpecialArgs sharedModules;};}
        ];
        specialArgs = {
          inherit
            brew
            flaky
            math
            nixpkgs
            nixpkgs-master
            nixpkgs-unstable
            ;
          dotfiles = self;
        };
      }
      attrs
    ]);

  ## Just like upstream `homeManagerConfiguration`, but add all of the
  ## `extraSpecialArgs` required by the configuration in this repo.
  homeManagerConfiguration = attrs:
    home-manager.lib.homeManagerConfiguration (recursiveMerge [
      {
        inherit extraSpecialArgs;
        modules = sharedModules;
      }
      attrs
    ]);

  ## Just like upstream `nixosSystem`, but adds all of the `specialArgs`
  ## required by the configuration in this repo (and the `extraSpecialArgs`
  ## required by the Home Manager configuration).
  nixosSystem = attrs:
    nixpkgs.lib.nixosSystem (recursiveMerge [
      {
        modules = [
          home-manager.nixosModules.default
          {home-manager = {inherit extraSpecialArgs sharedModules;};}
        ];
        specialArgs = {
          inherit
            agenix
            brew
            flaky
            math
            nixpkgs
            nixpkgs-master
            nixpkgs-unstable
            ;
          dotfiles = self;
        };
      }
      attrs
    ]);
}
