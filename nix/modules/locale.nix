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
          ## See
          ## https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table
          ## for symbol meanings.
          "1" = "y-MM-dd"; #         1972-01-27 – ISO 8601
          "2" = "y MMM d eeeeee"; #  1972 Jan 27, Th
          "3" = "eee, MMM d, y"; #   Thu, Jan 27, 1972
          "4" = "eeee, MMMM d, y"; # Thursday, January 27, 1972
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
