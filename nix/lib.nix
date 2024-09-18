{
  agenix,
  darwin,
  emacs-color-theme-solarized,
  flaky,
  home-manager,
  nixpkgs,
  org-invoice-table,
  self,
  system-manager,
}: let
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
      emacs-color-theme-solarized
      flaky
      nixpkgs
      org-invoice-table
      ;
    dotfiles = self;
  };
in {
  ## Just like upstream `darwinSystem`, but adds all of the `specialArgs`
  ## required by the configuration in this repo (and the `extraSpecialArgs`
  ## required by the Home Manager configuration).
  darwinSystem = attrs:
    darwin.lib.darwinSystem (recursiveMerge [
      {
        modules = [
          home-manager.darwinModules.default
          {home-manager = {inherit extraSpecialArgs;};}
        ];
        specialArgs = {
          inherit flaky nixpkgs;
          dotfiles = self;
        };
      }
      attrs
    ]);

  ## Just like upstream `homeManagerConfiguration`, but add all of the
  ## `extraSpecialArgs` required by the configuration in this repo.
  homeManagerConfiguration = attrs:
    home-manager.lib.homeManagerConfiguration (recursiveMerge [
      {inherit extraSpecialArgs;}
      attrs
    ]);

  makeSystemConfig = attrs:
    system-manager.lib.makeSystemConfig (recursiveMerge [
      {
        modules = [
          home-manager.nixosModules.default
          {home-manager = {inherit extraSpecialArgs;};}
        ];
        extraSpecialArgs = {
          inherit agenix flaky nixpkgs;
          dotfiles = self;
        };
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
          {home-manager = {inherit extraSpecialArgs;};}
        ];
        specialArgs = {
          inherit agenix flaky nixpkgs;
          dotfiles = self;
        };
      }
      attrs
    ]);
}
