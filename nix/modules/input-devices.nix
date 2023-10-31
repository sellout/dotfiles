{
  config,
  options,
  lib,
  pkgs,
  ...
}: {
  config =
    if options ? homebrew
    then {
      homebrew.casks = [
        # Atreus keyboard customizer
        "chrysalis" # not available on darwin via Nix
      ];
      system.keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };
    }
    else if options ? home
    then {
      home = {
        keyboard = {
          layout = "us";
          options = ["ctrl:nocaps"];
          variant = "dvorak";
        };
        packages = lib.optionals (pkgs.system == "x86_64-linux") [
          # Atreus keyboard customizer
          pkgs.chrysalis # packaged as x86_64-linux binary
        ];
      };
    }
    else {
      console.useXkbConfig = true;
      services = {
        fprintd.enable = true;
        xserver = {
          layout = "us, dvorak";
          # Enable touchpad support.
          libinput = {
            touchpad = {
              clickMethod = "clickfinger"; # don't right-click on right side of touchpad
              naturalScrolling = true;
              tapping = false; # disable tap-to-click
            };
          };
          xkbOptions = "ctrl:nocaps";
        };
      };
    };
}
