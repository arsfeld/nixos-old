
{ config, pkgs, lib, ... }:

with lib;

{
  boot.supportedFilesystems = [ "zfs" ];

  boot.zfs = {
    forceImportAll = false;
    extraPools = [ "data" ];
  };

  services.zfs.autoSnapshot.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "Wed *-1 02:00:00";
  services.zfs.trim.enable = true;

  services.znapzend = {
    enable = true;
    
    zetup = {
      "data/backups" = {
        # Make snapshots of tank/home every hour, keep those for 1 day,
        # keep every days snapshot for 1 month, etc.
        plan = "1d=>1h,1m=>1d,1y=>1m";
        recursive = true;
        destinations.local = {
          dataset = "backup/data/backups";
        };
      };
    };
  };
}
