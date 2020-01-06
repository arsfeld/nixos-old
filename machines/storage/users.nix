
{ config, pkgs, lib, ... }:

with lib;

{
  users.users = {
    arosenfeld = {
      isNormalUser = true;
      home = "/mnt/data/homes/arosenfeld";
      extraGroups = [ "wheel" "users" "media" "docker" "lxd" ];
    };
    camille = {
      uid = 1001;
      isNormalUser = true;
      group = "camille";
      home = "/mnt/data/homes/camille";
      extraGroups = [ "media" "users" ];
    };
    media = {
      isSystemUser = true;
      uid = 8675309;
      group = "media";
    };
  };

  users.groups.media.gid = 8675309;
  users.groups.arosenfeld.gid = 1000; 
  users.groups.camille.gid = 1001;
}