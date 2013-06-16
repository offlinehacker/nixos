{ config, pkgs, serverInfo, ... }:

let

  # Unpack anubis and put the config file in its root directory.
  anubisPHP = pkgs.stdenv.mkDerivation rec {
    name= "anubis-9999";

    src = pkgs.fetchgit {
      url = "https://github.com/pshep/ANUBIS.git";
      sha256 = "1mvpxsyvkmhix87xx69rcqy81xwdkqsxq9170m8fcx9p8kn7mi33";
      rev = "10281765d87c58ca953624000814d1ece50d5abb";
    };

    installPhase =
      ''
        ensureDir $out
        cp -r * $out

        sed -i 's/$dbdatabase = "anubis_db";/$dbdatabase = "${config.database}";/g' $out/config.inc.php
        sed -i 's/$dbusername = "anubis";/$dbusername = "${config.username}";/g' $out/config.inc.php
         sed -i 's/$dbpassword = "h3rakles";/$dbpassword = "${config.password}";/g' $out/config.inc.php
      '';
  };

in

{
  enablePHP = true;

  extraConfig = ''
    Alias ${config.urlPrefix}/ ${anubisPHP}/

    <Directory ${anubisPHP}>
      DirectoryIndex index.php
      Order deny,allow
      Allow from *
    </Directory>
  '';

  options = {

    urlPrefix = pkgs.lib.mkOption {
      default = "/anubis";
      description = "
        The URL prefix under which the anubis service appears.
        Use the empty string to have it appear in the server root.
      ";
    };

    database = pkgs.lib.mkOption {
      default = "anubis";
      description = ''
        Name of the mysql database.
      '';
    };

    username = pkgs.lib.mkOption {
      default = "anubis";
      description = ''
        Mysql username for database.
      '';
    };

    password = pkgs.lib.mkOption {
      default = "anubis";
      description = ''
        Mysql password for database.
      '';
    };
  };

}
