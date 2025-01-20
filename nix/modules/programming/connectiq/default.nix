## Garmin Connect IQ extension
{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.activities.programming.connectiq;
in {
  options.activities.programming.connectiq = {
    enable =
      lib.mkEnableOption
      "[Garmin Connect IQ](https://developer.garmin.com/connect-iq/)";

    enableVscodeIntegration =
      lib.mkEnableOption "support for Garmin Connect IQ development in VS Code";

    developerKeyPath = lib.mkOption {
      type = lib.types.path;
      description = ''
        The path to a file containing your Garmin Connect IQ developer key.
      '';
    };

    developerId = lib.mkOption {
      type = lib.types.str;
      description = ''
        Your developer ID for publishing.
      '';
    };

    jdkPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jdk21;
      description = ''
        The version of the Java SDK to use with Connect IQ.
      '';
    };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [(pkgs.callPackage ./connectiq-sdk-manager.nix {})];
      local.nixpkgs.allowedUnfreePackages = ["connectiq-sdk-manager"];
    }
    (lib.mkIf cfg.enableVscodeIntegration {
      ## FIXME: Connect IQ needs `java` in the `PATH`, but it would be better to
      ##        wrap VS Code, rather than injecting it for users.
      home.packages = [cfg.jdkPackage];
      programs.vscode = {
        extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "monkey-c";
            publisher = "garmin";
            version = "1.1.0";
            hash = "sha256-4CHBZA6dIdj8wpmW6ew/aGGB/h62DZkhyDM5jNchvDU=";
          }
        ];
        userSettings =
          {
            "monkeyC.javaPath" = cfg.jdkPackage;
          }
          // (
            if cfg ? developerKeyPath
            then {
              "monkeyC.developerKeyPath" = cfg.developerKeyPath;
            }
            else {}
          )
          // (
            if cfg ? developerId
            then {
              "monkeyC.developerId" = cfg.developerId;
            }
            else {}
          );
      };
    })
  ]);
}
