# D-Bus configuration and system bus daemon.
{
  config,
  lib,
  options,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.dbus;

  configDir = pkgs.makeDBusConf {
    suidHelper = "${pkgs.dbus.daemon}/libexec/dbus-daemon-launch-helper";
    serviceDirectories = cfg.packages;
  };
in {
  options = {
    ###### interface

    services.dbus = {
      enable = mkOption {
        type = types.bool;
        default = false;
        internal = true;
        description = lib.mdDoc ''
          Whether to start the D-Bus message bus daemon, which is
          required by many other system services and applications.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.dbus;
        defaultText = literalExpression "pkgs.dbus";
        description = "The package to use for D-Bus.";
      };

      packages = mkOption {
        type = types.listOf types.path;
        default = [];
        description = lib.mdDoc ''
          Packages whose D-Bus configuration files should be included in
          the configuration of the D-Bus system-wide or session-wide
          message bus.  Specifically, files in the following directories
          will be included into their respective DBus configuration paths:
          {file}`«pkg»/etc/dbus-1/system.d`
          {file}`«pkg»/share/dbus-1/system.d`
          {file}`«pkg»/share/dbus-1/system-services`
          {file}`«pkg»/etc/dbus-1/session.d`
          {file}`«pkg»/share/dbus-1/session.d`
          {file}`«pkg»/share/dbus-1/services`
        '';
      };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    # ran `dbus-uuidgen --ensure` manually, but it should happen during install
    environment.systemPackages = [cfg.package cfg.package.daemon];
    # environment.systemPackages = [ pkgs.dbus pkgs.dbus.daemon ];

    environment.etc."dbus-1".source = configDir;

    services.dbus.packages = [
      pkgs.dbus.out
      config.system.path
    ];

    # derived from
    # https://gitlab.freedesktop.org/dbus/dbus/-/blob/master/bus/org.freedesktop.dbus-session.plist.in
    launchd.agents."org.freedesktop.dbus-session".serviceConfig = {
      Label = "org.freedesktop.dbus-session";
      ProgramArguments = [
        "${pkgs.dbus}/bin/dbus-daemon"
        "--nofork"
        "--session"
      ];
      Sockets."unix_domain_listener".SecureSocketWithKey = "DBUS_LAUNCHD_SESSION_BUS_SOCKET";
    };

    environment.pathsToLink = ["/etc/dbus-1" "/share/dbus-1"];
  };
}
