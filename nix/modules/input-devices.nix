{
  config,
  flaky,
  lib,
  options,
  pkgs,
  ...
}: {
  config = flaky.lib.multiConfig options {
    darwinConfig = {
      homebrew.casks = [
        ## TODO: nix-darwin module doesn’t yet support 15.0 and brewCasks
        ##       package doesn’t work.
        "karabiner-elements"
      ];
      ## NB: Sometimes Karabiner won't work out of the box. Read
      ##     https://karabiner-elements.pqrs.org/docs/getting-started/installation/
      ##     to make sure all the extensions, etc. are enabled properly.
      services.karabiner-elements.enable = false;
      system.keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };
    };
    homeConfig = {
      home = {
        keyboard = {
          layout = "us";
          options = ["ctrl:nocaps"];
          variant = "dvorak";
        };
        packages = lib.optionals (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [
          ## Atreus keyboard customizer
          ## packaged in Nixpkgs as x86_64-linux binary
          (config.lib.local.maybeCask "chrysalis" null)
        ];
      };
      ## TODO: This should symlink the directory, not the file (see
      ##       https://karabiner-elements.pqrs.org/docs/manual/misc/configuration-file-path/#about-symbolic-link).
      xdg.configFile."karabiner/karabiner.json".text = let
        vendorId = {
          apple = 1452;
          keyboardio = 4617;
        };
        device = {
          atreus = {
            is_keyboard = true;
            product_id = 8963;
            vendor_id = vendorId.keyboardio;
          };
          touchBar = {
            is_keyboard = true;
            product_id = 34304;
            vendor_id = vendorId.apple;
          };
        };
      in
        lib.generators.toJSON {} {
          global = {
            ask_for_confirmation_before_quitting = true;
            check_for_updates_on_startup = false;
            enable_notification_window = true;
            show_in_menu_bar = true;
            show_profile_name_in_menu_bar = false;
            unsafe_ui = false;
          };
          profiles = lib.mapAttrsToList (name: value: value // {inherit name;}) {
            "Default profile" = {
              selected = true;

              virtual_hid_keyboard = {
                indicate_sticky_modifier_keys_state = true;
                keyboard_type_v2 = "ansi";
              };

              devices = [
                {
                  identifiers = device.atreus;
                  ignore = false;
                  disable_built_in_keyboard_if_exists = true;
                  ignore_vendor_events = true;
                  manipulate_caps_lock_led = true;
                }
                {
                  identifiers = device.touchBar;
                  ignore = false;
                  manipulate_caps_lock_led = true;
                  treat_as_built_in_keyboard = true;
                }
              ];
            };
          };
        };
    };
    nixosConfig = {
      console.useXkbConfig = true;
      services = {
        fprintd.enable = true;
        # Enable touchpad support.
        libinput.touchpad = {
          # don't right-click on right side of touchpad
          clickMethod = "clickfinger";
          naturalScrolling = true;
          tapping = false; # disable tap-to-click
        };
        xserver.xkb = {
          layout = "us,us";
          options = "ctrl:nocaps";
          variant = ",dvorak";
        };
      };
    };
  };
}
