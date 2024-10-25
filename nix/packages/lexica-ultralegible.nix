{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}: let
  pname = "lexica-ultralegible";
  version = "1.0.0";
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "jacobxperez";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-bz7O71k9GeCIUsvq0vU1rLuvKndIyHpoegTB4JMpRi4=";
    };

    installPhase = ''
      runHook preInstall

      install -Dm644 -t $out/share/fonts/opentype fonts/otf/*

      runHook postInstall
    '';

    meta = with lib; {
      description = ''
        A modern typeface inspired by the principles of legibility and
        readability, building on the foundation of the Atkinson Hyperlegible
        typeface
      '';
      homepage = "https://jacobxperez.github.io/lexica-ultralegible/";
      license = licenses.ofl;
      platforms = platforms.all;
      maintainers = with maintainers; [sellout];
    };
  }
