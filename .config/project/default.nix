{
  config,
  lib,
  pkgs,
  ...
}: {
  project = {
    name = "dotfiles";
    summary = "Sellout’s general configuration";

    devPackages = [pkgs.home-manager];
  };

  ## development
  project.file.".dir-locals.el".source = lib.mkForce ../emacs/.dir-locals.el;

  ## formatting
  programs.vale = {
    excludes = [
      "*.lisp"
      "./home/.local/bin/*"
      "./nix/modules/edit"
      "./nix/modules/emacs-pager"
      "./nix/modules/programming/envrc"
      "./nix/modules/programming/javascript/npmrc"
      "./nix/modules/vcs/git-bare"
      "./nix/modules/vcs/git-gc-branches"
      "./nix/modules/vcs/git-ls-subtrees"
      "./nix/modules/vcs/git/template/hooks/post-checkout"
    ];
    vocab.${config.project.name}.accept = [
      "dotfiles"
    ];
  };

  ## publishing
  services.github.settings.repository = {
    private = false;
    topics = [];
  };
}
