## TODO: Replace this with a general module for locales.
{
  bitbar-solar-time,
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

      ## Display apparent solar time in the macOS menu bar.
      home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        ## The file name indicates the refresh rate. Since the font isn’t
        ## `tnum`, setting it to `1m` avoids constant menubar jitter as the
        ## seconds change. (And we also rewrite the format string to hide the
        ## seconds.)
        "Library/Application Support/xbar/plugins/solar-time.1m.py" = {
          executable = true;
          ## TODO: There’s probably a nicer way to do this without making a
          ##       derivation just for this one file.
          text =
            lib.replaceStrings
            ["#!/usr/bin/env python" "\"☀️ \" + sun_time.strftime('%H:%M:%S"]
            ["#!${pkgs.python2}/bin/python" "sun_time.strftime('%H:%M"]
            (builtins.readFile "${bitbar-solar-time}/solar-time.1s.py");
        };
      };
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.xbar
      ];
      nixpkgs.config.permittedInsecurePackages = ["python-2.7.18.12"];

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
