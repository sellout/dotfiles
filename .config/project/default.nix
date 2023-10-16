{config, lib, ...}: {
  project = {
    name = "dotfiles";
    summary = "Sellout’s general configuration";
    ## This defaults to `true`, because I want most projects to be
    ## contributable-to by non-Nix users. However, Nix-specific projects can
    ## lean into Project Manager and avoid committing extra files.
    commit-by-default = lib.mkForce false;
  };

  ## dependency management
  services.renovate.enable = true;

  ## development
  project.file.".dir-locals.el".source = lib.mkForce ../emacs/.dir-locals.el;
  programs = {
    direnv = {
      enable = true;
      ## See the reasoning on `project.commit-by-default`.
      commit-envrc = false;
    };
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
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
        "*.el"
        "*.lisp"
        "./.github/workflows/flakehub-publish.yml"
        "./.github/settings.yml"
        "./home/.local/bin/*"
        "./root/etc/hosts"
      ];
      vocab.dotfiles.accept = config.programs.vale.vocab.base.accept ++ [
        "dotfiles"
      ];
    };
  };

  ## CI
  services.garnix = {
    enable = true;
    builds.exclude = [
      # TODO: Remove once garnix-io/garnix#285 is fixed.
      "homeConfigurations.x86_64-darwin-${config.project.name}-example"
    ];
  };

  ## publishing
  services = {
    flakehub.enable = true;
    github.enable = true;
  };
}
