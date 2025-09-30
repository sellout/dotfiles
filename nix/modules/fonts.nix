{
  flaky,
  options,
  pkgs,
  ...
}: let
  fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = ["Fira Mono"];
      sansSerif = ["Lexica Ultralegible"];
    };
  };
  packages = [
    pkgs.fira
    pkgs.fira-code
    pkgs.nerd-fonts.fira-code
    pkgs.fira-code-symbols
    pkgs.fira-mono
    pkgs.nerd-fonts.fira-mono
    pkgs.lexica-ultralegible
    ## https://github.com/liberationfonts
    pkgs.liberation_ttf
    pkgs.nerd-fonts.liberation
    ## https://opendyslexic.org/
    pkgs.open-dyslexic
    pkgs.nerd-fonts.open-dyslexic
  ];
in {
  config = flaky.lib.multiConfig options {
    darwinConfig.fonts = {inherit packages;};
    homeConfig = {
      fonts = {inherit fontconfig;};
      home = {inherit packages;};
    };
    nixosConfig.fonts = {inherit fontconfig packages;};
  };
}
