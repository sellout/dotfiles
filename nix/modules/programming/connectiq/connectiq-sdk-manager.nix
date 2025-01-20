## FIXME: This package should support Linux, but only has the darwin bits.
{
  fetchurl,
  lib,
  stdenv,
  undmg,
  unzip,
}:
stdenv.mkDerivation {
  pname = "connectiq-sdk-manager";
  version = "7.4.2";

  meta = {
    description = "Develop apps for Garmin devices.";
    homepage = "https://developer.garmin.com/connect-iq/";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [sellout];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
  };

  src = let
    url =
      "https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager"
      + (
        if stdenv.isDarwin
        then ".dmg"
        else "-linux.zip"
      );
  in
    fetchurl {
      inherit url;
      hash =
        if stdenv.isDarwin
        then "sha256-r9tJc53S2p9hOhwJrVA4HO7YVkhKEZJuwV5ievu1MiU="
        else "";
    };

  nativeBuildInputs = [
    undmg
    unzip
  ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    cp -r *.app $out/Applications
  '';
}
