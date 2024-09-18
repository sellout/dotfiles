{lib, ...}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
      "1password-cli"
      "eagle"
      "onepassword-password-manager"
      "plexmediaserver"
      "steam"
      "steam-original"
      "steam-run"
      "vscode-extension-ms-vsliveshare-vsliveshare"
      "zoom"
    ];
}
