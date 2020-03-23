
{ config, pkgs, lib, ... }:

with lib;

{

  services.restic.backups = {
      homeb2 = {
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

  systemd = {
    timers.rclone-sync = {
      wantedBy = [ "timers.target" ];
      partOf = [ "rclone-sync.service" ];
      timerConfig.OnCalendar = "daily";
    };
    services.rclone-sync = let 
        rcloneOptions = "--fast-list -P --stats-one-line";
    in {
      serviceConfig.Type = "oneshot";
      serviceConfig.User = "arosenfeld";
      script = ''
        ${pkgs.rclone}/bin/rclone sync ${rcloneOptions} dropbox: ~/Dropbox
        ${pkgs.rclone}/bin/rclone sync ${rcloneOptions} gdrive: ~/Google\ Drive
        ${pkgs.rclone}/bin/rclone sync ${rcloneOptions} onedrive: ~/One\ Drive
        ${pkgs.rclone}/bin/rclone sync ${rcloneOptions} nextcloud: ~/Nextcloud
      '';
    };
  };
}
