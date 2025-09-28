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

  ## dependency management
  services.renovate.enable = true;

  ## development
  project.file.".dir-locals.el".source = lib.mkForce ../emacs/.dir-locals.el;
  programs = {
    direnv.enable = true;
    git.enable = true;
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt.enable = true;
    vale = {
      enable = true;
      coreSettings.Vocab = "dotfiles";
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
        "./root/etc/hosts"
      ];
      vocab.${config.project.name}.accept = [
        "dotfiles"
      ];
    };
  };

  ## CI
  services.garnix.enable = true;

  ## publishing
  services = {
    flakehub.enable = true;
    github.enable = true;
  };
}
