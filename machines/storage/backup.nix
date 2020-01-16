
{ config, pkgs, lib, ... }:

with lib;

{

  services.restic.backups = {
      localbackup = {
        paths = [ "/mnt/data/homes" "/var/lib/plex" "/var/nas" ];
        repository = "b2:arosenfeld-backup:backups";
        passwordFile = "/etc/secrets/restic";
        s3CredentialsFile = "/etc/secrets/b2.keys";
        extraOptions = [
          "--verbose"
          "--one-file-system"
        ];
        timerConfig = {
          OnCalendar = "Mon 03:00:00";
        };
      };
  };
}
