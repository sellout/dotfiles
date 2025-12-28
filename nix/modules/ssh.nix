{
  config,
  lib,
  pkgs,
  ...
}: let
  runtimeDir = "${config.lib.local.xdg.runtimeDir}/ssh";

  ## `runtimeDir` intentionally gets wiped after the last logout, so we need to
  ## ensure that login shells recreate it.
  profileExtra = ''
    mkdir -p ${lib.escapeShellArg runtimeDir}
  '';

  cfg = config.programs.ssh;
in {
  options.programs.ssh = {
    knownHosts = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf lib.types.attrs);
      default = null;
      description = ''
        A list of known_hosts entries. If this is set, it is used instead of
        `userKnownHostsFile`.
      '';
    };
    extraKnownHosts = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = ''
        A list of known_hosts entries. If this is set, it is used instead of
        `userKnownHostsFile`.
      '';
    };
  };
  config = let
    ## Get keychain to use an XDG-compatible location.
    keychainFlags = [
      "--absolute"
      "--dir"
      "${config.lib.local.xdg.runtimeDir}/keychain"
    ];
  in {
    programs.bash = {inherit profileExtra;};
    programs.zsh = {inherit profileExtra;};
    xsession = {inherit profileExtra;};

    programs.keychain = {
      enable = true;
      ## This is done instead of `programs.keychain.extraArgs` because that only
      ## applies to the initial setup. We also can’t easily get away with adding
      ## it via `home.shellAliases` because there are contexts (Emacs) that run
      ## it outside of a shell environment, so then it still gets overlooked.
      package = pkgs.keychain.overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [pkgs.makeWrapper];
        postFixup = ''
          wrapProgram "$out/bin/keychain" \
            --add-flags "${lib.escapeShellArgs keychainFlags}"
        '';
      });
      extraFlags = keychainFlags;
      keys = ["id_ed25519"];
    };

    programs.ssh = {
      enable = true;
      package = pkgs.openssh;
      enableDefaultConfig = false;
      extraConfig = ''
        AddKeysToAgent yes
      '';
      matchBlocks."*" = {
        controlMaster = "auto";
        # This moves the default `controlPath`, but also changes %n to %h, so we
        # share the connection even if we typed different hostnames on the
        # command-line.
        controlPath = "${runtimeDir}/master-%r@%h:%p";
        # Don’t kill the socket as soon as the primary connection dies. Give us
        # 10 minutes to start a new session.
        controlPersist = "10m";
        ## See
        ## https://heipei.github.io/2015/02/26/SSH-Agent-Forwarding-considered-harmful/
        forwardAgent = false;
      };
      userKnownHostsFile = let
        entries =
          (
            if cfg.knownHosts != null
            then
              builtins.concatLists (lib.mapAttrsToList
                (name: value:
                  map
                  (key: "${lib.concatStringsSep "," value.names or [name]} ${key.format} ${key.data}")
                  value.keys)
                cfg.knownHosts)
            else []
          )
          ++ (
            if lib.isList cfg.extraKnownHosts
            then cfg.extraKnownHosts
            else []
          );
      in
        lib.mkIf (entries != [])
        (toString (pkgs.writeText "known_hosts" (lib.concatLines entries)));
    };
  };
}
