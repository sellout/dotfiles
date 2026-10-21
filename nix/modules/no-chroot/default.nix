## Home Manager derivations that need unsandboxing (see ./lib.nix).
{
  lib,
  pkgs,
  ...
}: let
  inherit (import ./lib.nix lib) noChroot noChrootFor;
in {
  ## The activation package is defined directly, so we can redefine the option
  ## with an `apply` that will merge.
  options.home.activationPackage = lib.mkOption {apply = noChroot;};

  ## Home Manager’s Emacs module packages `programs.emacs.extraConfig` with the
  ## Emacs package set’s `trivialBuild`.
  config.programs.emacs.overrides = final: prev: let
    ## The wrapper builds its derivations with `runCommand`, which we can’t
    ## overlay globally (it recurses through stdenv), so we re-instantiate the
    ## wrapper with our own.
    emacsWithPackages =
      pkgs.callPackage
      "${pkgs.path}/pkgs/applications/editors/emacs/build-support/wrapper.nix"
      {
        runCommand = name: env: script:
          noChroot (pkgs.runCommand name env script);
      }
      final;
  in {
    inherit emacsWithPackages;
    withPackages = emacsWithPackages;
    trivialBuild = args:
      noChrootFor ["emacs-default-0.1.0"] (prev.trivialBuild args);
  };

  ## The other derivations are defined in `let`s, so we can only access them
  ## through the builder.
  config.nixpkgs.overlays = [
    (final: prev: {
      buildEnv = args:
        noChrootFor [
          "home-manager-applications"
          "home-manager-fonts"
          "home-manager-path"
        ] (prev.buildEnv args);
      ## Home Manager’s Emacs module writes `programs.emacs.extraConfig` here.
      writeText = name: text:
        noChrootFor ["default.el"] (prev.writeText name text);
      writeShellScript = name: text:
        noChrootFor ["activation-script"] (prev.writeShellScript name text);
    })
  ];
}
