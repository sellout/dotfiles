{
  emacs-color-theme-solarized,
  flake-utils,
  mkalias,
  nixpkgs,
  nixpkgsConfig,
  unison,
}: final: prev: let
  # On aarch64-darwin, this gives us a Rosetta fallback, otherwise, it’s a NOP.
  x86_64 =
    if final.system == flake-utils.lib.system.aarch64-darwin
    then
      import nixpkgs {
        config = nixpkgsConfig;
        localSystem = flake-utils.lib.system.x86_64-darwin;
        overlays = [unison.overlays.default];
      }
    else prev;
in {
  inherit emacs-color-theme-solarized;
  ## enable this if I play with getting dbus working again
  # emacs = prev.emacs.overrideAttrs (old: {
  #   buildInputs = [ final.dbus ] ++ old.buildInputs;
  # });
  emacs = final.emacs29;
  emacsPackagesFor = emacs:
    (prev.emacsPackagesFor emacs).overrideScope' (efinal: eprev: {
      ## still waffling between `direnv` and `envrc`. `direnv` has at least an
      ## attempt at TRAMP support, but `envrc` seems generally better.
      direnv = eprev.direnv.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ## adds TRAMP support (wbolster/emacs-direnv#68)
            (final.fetchpatch {
              name = "direnv-tramp.patch";
              url = "https://patch-diff.githubusercontent.com/raw/wbolster/emacs-direnv/pull/68.patch";
              sha256 = "sha256-j+d6ffFU0d3a9dxPbMAfBPlLvs77tdksdRw2Aal3mSc=";
            })
          ];
      });
      envrc = eprev.envrc.overrideAttrs (old: {
        ## adds TRAMP support (purcell/envrc#29)
        src = final.fetchFromGitHub {
          owner = "siddharthverma314";
          repo = "envrc";
          rev = "master";
          sha256 = "yz2B9c8ar9wc13LwAeycsvYkCpzyg8KqouYp4EBgM6A=";
        };
      });
      floobits = eprev.floobits.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ## Fixes warnings.
            (final.fetchpatch {
              name = "floobits-warnings.patch";
              url = "https://patch-diff.githubusercontent.com/raw/Floobits/floobits-emacs/pull/103.patch";
              sha256 = "sha256-/XhrSIKDqaitV3Kk+JkOgflgl3821m/8gLrP0yHENP0=";
            })
          ];
      });
      ## NB: This should be a flake input, as it’s my own library, but there
      ##     isn’t currently flake support for Pijul, so it needs to be fetched
      ##     traditionally.
      vc-pijul = efinal.trivialBuild {
        pname = "vc-pijul";
        version = "0.1.0";

        src =
          (final.fetchpijul {
            url = "https://ssh.pijul.com/sellout/vc-pijul";
            hash = "sha256-FNZSHYpkvZOdhDP4sD2z+DNkHDIKW1NI52nEs4o3WC8=";
          })
          .overrideAttrs (old: {
            ## FIXME: `pijul clone` is complaining about a bad certificate, so we
            ##        add the `-k` flag to ignore certificates, which is not good.
            installPhase = ''
              set -x
              runHook preInstall

              pijul clone \
                ''${change:+--change "$change"} \
                -k \
                ''${state:+--state "$state"} \
                --channel "$channel" \
                "$url" \
                "$out"

              runHook postInstall
            '';
          });

        meta = {
          homepage = "https://nest.pijul.com/sellout/vc-pijul";
          description = "Pijul integration for Emacs’ VC library";
          license = final.lib.licenses.gpl3Plus;
          maintainers = [final.lib.maintainers.sellout];
        };
      };
      wakatime-mode = eprev.wakatime-mode.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ## Fixes wakatime/wakatime-mode#67 among other changes.
            (final.fetchpatch {
              name = "wakatime-overhaul.patch";
              url = "https://github.com/sellout/wakatime-mode/commit/2afa46537bae42afc134951963198d91a686db02.patch";
              sha256 = "bj3dFx0XXIv2AREuM7/EbiW0RhI9fmpbXPazOpI2an8=";
            })
          ];
      });
    });

  ## Idris 1 doesn’t build on Nixpkgs 23.11.
  idris = final.idris2;

  mkalias = mkalias.packages.${final.system}.mkalias;

  ## I don’t even use Python, but sometimes it’s forced upon me, and Python 2 is
  ## EOL, so don’t let anything use it.
  python = final.python3;
  pythonPackages = final.python3Packages;

  unison-ucm = x86_64.unison-ucm;
}
