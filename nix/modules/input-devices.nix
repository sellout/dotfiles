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
        # Atreus keyboard customizer
        "chrysalis" # not available on darwin via Nix
      ];
      ## NB: Sometimes Karabiner won't work out of the box. Read
      ##     https://karabiner-elements.pqrs.org/docs/getting-started/installation/
      ##     to make sure all the extensions, etc. are enabled properly.
      services.karabiner-elements.enable = true;
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
        packages = lib.optionals (pkgs.system == "x86_64-linux") [
          # Atreus keyboard customizer
          pkgs.chrysalis # packaged as x86_64-linux binary
        ];
      };
      xdg.configFile."karabiner/karabiner.json".text = lib.generators.toJSON {} {
        global = {
          ask_for_confirmation_before_quitting = true;
          check_for_updates_on_startup = false;
          show_in_menu_bar = true;
          show_profile_name_in_menu_bar = false;
          unsafe_ui = false;
        };
        profiles."Default profile" = {
          complex_modifications = {
            parameters = {
              "basic.simultaneous_threshold_milliseconds" = 50;
              "basic.to_delayed_action_delay_milliseconds" = 500;
              "basic.to_if_alone_timeout_milliseconds" = 1000;
              "basic.to_if_held_down_threshold_milliseconds" = 500;
              "mouse_motion_to_scroll.speed" = 100;
            };
            rules = [];
          };
          devices = [
            {
              disable_built_in_keyboard_if_exists = true;
              fn_function_keys = [];
              identifiers = {
                is_keyboard = true;
                product_id = 8963; # Atreus
                vendor_id = 4617; # Keyboardio
              };
              ignore = false;
              manipulate_caps_lock_led = true;
              simple_modifications = [];
              treat_as_built_in_keyboard = false;
            }
          ];
          fn_function_keys = [
            {
              from.key_code = "f1";
              to = [{consumer_key_code = "display_brightness_decrement";}];
            }
            {
              from.key_code = "f2";
              to = [{consumer_key_code = "display_brightness_increment";}];
            }
            {
              from.key_code = "f3";
              to = [{apple_vendor_keyboard_key_code = "mission_control";}];
            }
            {
              from.key_code = "f4";
              to = [{apple_vendor_keyboard_key_code = "spotlight";}];
            }
            {
              from.key_code = "f5";
              to = [{consumer_key_code = "dictation";}];
            }
            {
              from.key_code = "f6";
              to = [{key_code = "f6";}];
            }
            {
              from.key_code = "f7";
              to = [{consumer_key_code = "rewind";}];
            }
            {
              from.key_code = "f8";
              to = [{consumer_key_code = "play_or_pause";}];
            }
            {
              from.key_code = "f9";
              to = [{consumer_key_code = "fast_forward";}];
            }
            {
              from.key_code = "f10";
              to = [{consumer_key_code = "mute";}];
            }
            {
              from.key_code = "f11";
              to = [{consumer_key_code = "volume_decrement";}];
            }
            {
              from.key_code = "f12";
              to = [{consumer_key_code = "volume_increment";}];
            }
          ];
          parameters.delay_milliseconds_before_open_device = 1000;
          selected = true;
          simple_modifications = [];
          virtual_hid_keyboard = {
            country_code = 0;
            indicate_sticky_modifier_keys_state = true;
            mouse_key_xy_scale = 100;
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
