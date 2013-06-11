{ config, pkgs, ... }:

with pkgs.lib;

let
  cfg = config.services.cgminer;

  foldedHwConfig = foldAttrs (n: a: [n] ++ a) [] cfg.hardware;
  mergedHwConfig = mapAttrsToList (n: v: ''"${n}": "${(concatStringsSep "," (map toString v))}"'') foldedHwConfig;
  mergedConfig = mapAttrsToList (n: v: ''"${n}":  ${''"'' if lib.isBool v else ""} ${toString v} ${''"'' if lib.isBool v else ""}'') cfg.config;

  cgminerConfig = pkgs.writeText "cgminer.conf" ''
  {
  ${concatStringsSep mergedHwConfig "\n"}
  ${concatStringsSep mergedConfig "\n"}
  "pools": [
    ${concatMapStrings (v: ''{"url": "${v.url}", "user": "${v.user}", "pass": "${v.pass}"\n}'') cfg.pools}
  ]
  }
  '';
in
{
  ###### interface
  options = {

    services.cgminer = {

      enable = mkOption {
        default = false;
        description = "Whether to enable the cgminer.";
      };

      package = mkOption {
        default = pkgs.cgminer;
        description = "Which cgminer derivation to use.";
      };

      user = mkOption {
        default = "cgminer";
        description = "User account under which cgminer runs";
      };

      pools = mkOption {
        default = [];  # Run benchmark
        description = "List of pools where to mine";
        example = [{
          url = "http://p2pool.org:9332",
          username = "17EUZxTvs9uRmPsjPZSYUU3zCz9iwstudk",
          password="X"}]
      };

      hardware = mkOption {
        default = []; # Run without options
        description= "List of config options for every GPU";
        example = [{
          intensity = 20;
          vectors = 1;
          worksize = 256;
          lookup-gap = 2;
          thread-concurrency = 0;
          kernel = "scrypt";
        }];
      };

      config = mkOption {
        default = [];
        description = "Additional config";
        example = {
          scrypt = true;
          shares = 0;
        };
      };
    };
  };


  ###### implementation

  config = mkIf config.services.cgminer.enable {

    users.extraUsers = singleton
      { name = cfg.user;
        description = "Cgminer user";
      };

    environment.systemPackages = [ cfg.package ];

  systemd.services.cgminer = {
    path = [ pkgs.cgminer ];

    after = [ "display-manager.target" "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = { 
      LD_LIBRARY_PATH = ''/run/opengl-driver/lib:/run/opengl-driver-32/lib'';
      DISPLAY = ":0";
      GPU_MAX_ALLOC_PERCENT = "100";
      GPU_USE_SYNC_OBJECTS = "1";
    };

    serviceConfig = {
      ExecStart = "${pkgs.cgminer}/bin/cgminer -c ${cgminerConfig}";
      User = cfg.user
      Restart = "always";
      RestartSec = 10;
    };
  };
 
}
