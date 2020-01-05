
{ config, pkgs, lib, ... }:

with lib;

{
  boot.supportedFilesystems = [ "zfs" ];

  boot.zfs = {
    forceImportAll = false;
  };

  #services.zfs.autoSnapshot.enable = true;
  services.zfs.autoScrub.enable = true;
  #services.zfs.trim.enabled = true;

}