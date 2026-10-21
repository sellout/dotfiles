## nix-darwin derivations that need unsandboxing (see ./lib.nix).
{
  config,
  lib,
  ...
}: let
  inherit (import ./lib.nix lib) noChroot noChrootFor;
in {
  ## `system.build` is declared without an `apply`, so we can add one.
  options.system.build = lib.mkOption {
    apply = build: build // {toplevel = noChroot build.toplevel;};
  };

  ## Home Manager’s nix-darwin module builds each user’s activation wrapper
  ## inside a `let`, with the system’s `pkgs`.
  config.nixpkgs.overlays = [
    (final: prev: {
      writeShellScript = name: text:
        noChrootFor
        (map (user: "activation-${user}")
          (lib.attrNames config.home-manager.users))
        (prev.writeShellScript name text);
    })
  ];
}
