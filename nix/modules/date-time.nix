{
  lib,
  pkgs,
  ...
}: {
  ## Auto-adjust system time.
  ## See NixOS/nixpkgs#68489 for the current mess of this situation.
  location.provider = "geoclue2";
  services.automatic-timezoned.enable = true;
  services.geoclue2 = {
    enable = true; # This is ostensibly redundant with `location.provider`.
    enableDemoAgent = lib.mkForce true;
    geoProviderUrl = "https://beacondb.net/v1/geolocate";
  };

  ## Since the automatic time-zone setting doesn’t seem to be working, this
  ## allows `tzupdate` to bring the time zone in sync with the current location.
  ## See NixOS/nixpkgs#127984 for more context.
  services.tzupdate = {
    enable = true;
    timer.enable = true;
  };
  time.timeZone = null;
}
