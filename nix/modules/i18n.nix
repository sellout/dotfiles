{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.i18n.spelling;
in {
  options.i18n.spelling = {
    enable = lib.mkEnableOption "spelling dictionaries";

    dictionaries = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {};
      description = ''
        For each language code (e.g., “en”), produces a local dictionary for
        that language containing the listed words. The dictionary “local” will
        be applied to all languages (it is mostly for proper nouns – words that
        might be used regardless of the language).
      '';
    };
  };
  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) (let
    localDictionary =
      if cfg.dictionaries ? local
      then {
        "Library/Spelling/LocalDictionary".text =
          lib.concatLines cfg.dictionaries.local;
      }
      else {};
    langDictionaries =
      lib.concatMapAttrs
      (name: value: {"Library/Spelling/${name}".text = lib.concatLines value;})
      (lib.removeAttrs cfg.dictionaries ["local"]);
  in {
    home.file = langDictionaries // localDictionary;
  });
}
