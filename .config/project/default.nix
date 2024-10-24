{
  config,
  lib,
  pkgs,
  ...
}: {
  project = {
    name = "dotfiles";
    summary = "Sellout’s general configuration";
    ## This defaults to `true`, because I want most projects to be
    ## contributable-to by non-Nix users. However, Nix-specific projects can
    ## lean into Project Manager and avoid committing extra files.
    commit-by-default = lib.mkForce false;

    devPackages = [pkgs.home-manager];
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
        "./home/.config/npm/npmrc"
        "./home/.local/bin/*"
        "./root/etc/hosts"
      ];
      vocab.${config.project.name}.accept = [
        "dotfiles"
      ];
    };
  };

  ## CI
  services.garnix = {
    enable = true;
    builds."*".exclude = [
      # TODO: Remove once NixOS/nix#4119 is fixed.
      "darwinConfigurations.aarch64-darwin-example"
      "homeConfigurations.aarch64-darwin-example"
      # TODO: Remove once garnix-io/garnix#285 is fixed.
      "darwinConfigurations.x86_64-darwin-example"
      "darwinConfigurations.x86_64-darwin-example-bare"
      "homeConfigurations.x86_64-darwin-example"
    ];
  };

  ## publishing
  services = {
    flakehub.enable = true;
    github.enable = true;
  };
}
