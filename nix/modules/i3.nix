{
  config,
  lib,
  pkgs,
  ...
}: let
  defaultFont = config.lib.local.defaultFont;
in {
  xsession.windowManager.i3 = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (let
    # the default font gets trampled by home-manager setting a font for the
    # bars no matter what, so this lets us define a common font to use.
    font = "pango:" + defaultFont.string;
    mod = "Mod4";
    refresh_i3status = "killall -SIGUSR1 i3status";
    ws1 = "1";
    ws2 = "2";
    ws3 = "3: Signal";
    ws4 = "4: Ferdium";
    ws5 = "5: Video";
    ws6 = "6";
    ws7 = "7: Emacs";
    ws8 = "8: Firefox";
    ws9 = "9";
    ws10 = "10";
  in {
    config = {
      bars = [
        {
          fonts = {
            names = [defaultFont.sansFamily];
            size = defaultFont.size;
          };
          statusCommand = "i3status";
        }
      ];
      floating.modifier = mod;
      fonts = {
        names = [defaultFont.sansFamily];
        size = defaultFont.size;
      };
      keybindings =
        lib.mkOptionDefault
        {
          # Use pactl to adjust volume in PulseAudio.
          "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && ${refresh_i3status}";
          "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && ${refresh_i3status}";
          "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && ${refresh_i3status}";
          "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && ${refresh_i3status}";

          # start a terminal
          "${mod}+Return" = "exec i3-sensible-terminal";

          # kill focused window
          "${mod}+Shift+q" = "kill";

          # start dmenu (a program launcher)
          "${mod}+d" = "exec dmenu_run";
          # There also is the (new) i3-dmenu-desktop which only displays applications
          # shipping a .desktop file. It is a wrapper around dmenu, so you need that
          # installed.
          # "${mod}+d exec --no-startup-id i3-dmenu-desktop";

          # change focus
          "${mod}+j" = "focus left";
          "${mod}+k" = "focus down";
          "${mod}+l" = "focus up";
          "${mod}+semicolon" = "focus right";

          # alternatively, you can use the cursor keys:
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";

          # move focused window
          "${mod}+Shift+j" = "move left";
          "${mod}+Shift+k" = "move down";
          "${mod}+Shift+l" = "move up";
          "${mod}+Shift+semicolon" = "move right";

          # move workspoce
          "${mod}+p" = "move workspace to output left";
          "${mod}+n" = "move workspace to output right";

          # alternatively, you can use the cursor keys:
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";

          # split in horizontal orientation
          "${mod}+h" = "split h";

          # split in vertical orientation
          "${mod}+v" = "split v";

          # enter fullscreen mode for the focused container
          "${mod}+f" = "fullscreen toggle";

          # change container layout (stacked, tabbed, toggle split)
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";

          # toggle tiling / floating
          "${mod}+Shift+space" = "floating toggle";

          # change focus between tiling / floating windows
          "${mod}+space" = "focus mode_toggle";

          # focus the parent container
          "${mod}+a" = "focus parent";

          # focus the child container
          # "${mod}+d" = "focus child";

          # switch to workspace
          "${mod}+1" = "workspace number ${ws1}";
          "${mod}+2" = "workspace number ${ws2}";
          "${mod}+3" = "workspace number ${ws3}";
          "${mod}+4" = "workspace number ${ws4}";
          "${mod}+5" = "workspace number ${ws5}";
          "${mod}+6" = "workspace number ${ws6}";
          "${mod}+7" = "workspace number ${ws7}";
          "${mod}+8" = "workspace number ${ws8}";
          "${mod}+9" = "workspace number ${ws9}";
          "${mod}+0" = "workspace number ${ws10}";

          # move focused container to workspace
          "${mod}+Shift+1" = "move container to workspace number ${ws1}";
          "${mod}+Shift+2" = "move container to workspace number ${ws2}";
          "${mod}+Shift+3" = "move container to workspace number ${ws3}";
          "${mod}+Shift+4" = "move container to workspace number ${ws4}";
          "${mod}+Shift+5" = "move container to workspace number ${ws5}";
          "${mod}+Shift+6" = "move container to workspace number ${ws6}";
          "${mod}+Shift+7" = "move container to workspace number ${ws7}";
          "${mod}+Shift+8" = "move container to workspace number ${ws8}";
          "${mod}+Shift+9" = "move container to workspace number ${ws9}";
          "${mod}+Shift+0" = "move container to workspace number ${ws10}";

          # reload the configuration file
          "${mod}+Shift+c" = "reload";
          # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
          "${mod}+Shift+r" = "restart";
          # exit i3 (logs you out of your X session)
          "${mod}+Shift+e" = "exec \"i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'\"";

          "${mod}+r" = "mode \"resize\"";
        };
      modes = {
        resize = {
          # These bindings trigger as soon as you enter the resize mode

          # Pressing left will shrink the window’s width.
          # Pressing right will grow the window’s width.
          # Pressing up will shrink the window’s height.
          # Pressing down will grow the window’s height.
          "j" = "resize shrink width 10 px or 10 ppt";
          "k" = "resize grow height 10 px or 10 ppt";
          "l" = "resize shrink height 10 px or 10 ppt";
          "semicolon" = "resize grow width 10 px or 10 ppt";

          # same bindings, but for the arrow keys
          "Left" = "resize shrink width 10 px or 10 ppt";
          "Down" = "resize grow height 10 px or 10 ppt";
          "Up" = "resize shrink height 10 px or 10 ppt";
          "Right" = "resize grow width 10 px or 10 ppt";

          # back to normal: Enter or Escape or ${mod+r
          "Return" = "mode \"default\"";
          "Escape" = "mode \"default\"";
          "${mod}+r" = "mode \"default\"";
        };
      };
      modifier = mod;
      startup = [
        # The combination of xss-lock, nm-applet and pactl is a popular choice, so
        # they are included here as an example. Modify as you see fit.

        # Sets up the resolution for the current display layout
        {
          command = "autorandr --change";
          always = true;
        }
        # NetworkManager is the most popular way to manage wireless networks on Linux,
        # and nm-applet is a desktop environment-independent system tray GUI for it.
        {command = "nm-applet";}

        # regularly-used apps
        {command = "emacs";}
        {command = "ferdi";}
        {command = "signal-desktop";}
        {command = "firefox";}
      ];
      workspaceAutoBackAndForth = true;
    };

    enable = true;
    extraConfig = ''
      workspace "${ws1}" output eDP-1
      workspace "${ws2}" output eDP-1
      workspace "${ws3}" output eDP-1
      workspace "${ws4}" output eDP-1
      workspace "${ws5}" output eDP-1
      workspace "${ws6}" output DP-1
      workspace "${ws7}" output DP-1
      workspace "${ws8}" output DP-1
      workspace "${ws9}" output DP-1
      workspace "${ws10}" output DP-1
    '';
  });
}
