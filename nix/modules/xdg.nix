{
  config,
  lib,
  pkgs,
  ...
}: {
  ## TODO: Remove once nix-community/home-manager#7937 is in a release.
  home.packages = [pkgs.xdg-user-dirs];

  ## Variables that `config.xdg` doesn’t provide, but that I wish it would.
  lib.local.xdg = {
    bin = {
      home = config.lib.local.addHome config.lib.local.xdg.bin.rel;
      rel = "${config.lib.local.xdg.local.rel}/bin";
    };
    cache.rel = config.lib.local.removeHome config.xdg.cacheHome;
    config.rel = config.lib.local.removeHome config.xdg.configHome;
    data.rel = config.lib.local.removeHome config.xdg.dataHome;
    local = {
      home = config.lib.local.addHome config.lib.local.xdg.local.rel;
      rel = lib.removeSuffix "/state" config.lib.local.xdg.state.rel;
    };
    state.rel = config.lib.local.removeHome config.xdg.stateHome;
    # Don’t know why this one isn’t in the `xdg` module.
    runtimeDir = config.home.sessionVariables.XDG_RUNTIME_DIR;
    ## TODO: Would like this to be in ./programming/default.nix, but attrs under
    ##      `lib` don’t merge nicely.
    userDirs.projects = {
      home =
        config.lib.local.addHome config.lib.local.xdg.userDirs.projects.rel;
      rel = "Projects";
    };
  };

  xdg = {
    enable = true;
    ## TODO: Remove once nix-community/home-manager#7937 is in a release.
    configFile = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      "user-dirs.conf".text = "enabled=False";
      "user-dirs.dirs".text = ''
        XDG_DESKTOP_DIR="$HOME/Desktop"
        XDG_DOCUMENTS_DIR="$HOME/Documents"
        XDG_DOWNLOAD_DIR="$HOME/Downloads"
        XDG_MUSIC_DIR="$HOME/Music"
        XDG_PICTURES_DIR="$HOME/Pictures"
        XDG_PROJECTS_DIR="$HOME/Projects"
        XDG_PUBLICSHARE_DIR="$HOME/Public"
        XDG_TEMPLATES_DIR="$HOME/Templates"
        XDG_VIDEOS_DIR="$HOME/Movies"
      '';
    };
    userDirs = {
      ## TODO: Use `true` once  nix-community/home-manager#7937 is in a release.
      enable = pkgs.stdenv.hostPlatform.isLinux;
      createDirectories = true;
      ## TODO: Uncomment once  nix-community/home-manager#7937 is in a release.
      # setSessionVariables = false;
      videos =
        lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        (config.lib.local.addHome "Movies");
    };
  };
}
