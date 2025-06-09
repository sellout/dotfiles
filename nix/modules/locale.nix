## TODO: Replace this with a general module for locales.
{
  flaky,
  lib,
  options,
  pkgs,
  ...
}: let
  baseLocale = "en_US";
  fullLocale = "${baseLocale}.UTF-8";
  ## This is a way to get an ISO datetime with English.
  timeLocale = "en_DK.UTF-8";
in {
  config = flaky.lib.multiConfig options {
    homeConfig = {
      ## FIXME: macOS doesn’t support the `en_DK` locale.
      home.language =
        if pkgs.stdenv.isDarwin
        then {
          base = fullLocale;
        }
        else {
          base = fullLocale;
          time = timeLocale;
        };

      targets.darwin.defaults.NSGlobalDomain = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        AppleFirstWeekday.gregorian = 2; # Monday
        AppleICUDateFormatStrings = {
          # See
          # https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table
          # for symbol meanings.
          "1" = "y-MM-dd"; # Iso
          "2" = "MMM d, y";
          "3" = "EEE, MMM d, y";
          "4" = "EEEE, MMMM d, y";
        };
        AppleICUForce12HourTime = false;
        AppleICUForce24HourTime = true;
        AppleLanguages = ["en"];
        AppleLocale = baseLocale;
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = true;
        AppleICUNumberSymbols = let
          decimalSeparator = ".";
          groupSeparator = " "; # NARROW NO-BREAK SPACE
        in {
          "0" = decimalSeparator;
          "1" = groupSeparator;
          "10" = decimalSeparator;
          "17" = groupSeparator;
        };
        ## I prefer Rankine, but it’s easy to convert from Fahrenheit by adding
        ## 460⠊.
        AppleTemperatureUnit = "Fahrenheit";
        ## Pairs of open/close quotes, in order of nesting.
        NSUserQuotesArray = ["“" "”" "‘" "’"];
      };
    };

    nixosConfig = {
      i18n = {
        defaultLocale = fullLocale;
        extraLocaleSettings.LC_TIME = timeLocale;
        supportedLocales = ["all"]; # How big can these things be?
      };
    };
  };
}
