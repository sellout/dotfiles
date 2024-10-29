{
  lib,
  pkgs,
  ...
}: {
  ## TODO: Replace these with my ./locale.nix module
  ## TODO: Only set these if the locale is available on the system.
  home.language = {
    base = "en_US.UTF-8";
    time = "en_DK.UTF-8"; # “joke” value for getting ISO datetimes
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
    AppleICUForce24HourTime = 1;
    AppleLanguages = ["en"];
    AppleLocale = "en_US";
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
    AppleTemperatureUnit = "Celsius";
    ## Pairs of open/close quotes, in order of nesting.
    NSUserQuotesArray = ["“" "”" "‘" "’"];
  };
}
