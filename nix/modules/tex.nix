{
  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: {
      inherit
        (tpkgs)
        braids
        dvipng
        pgf
        scheme-small
        tikz-cd
        ulem
        wrapfig
        xcolor
        ;
    };
  };
}
