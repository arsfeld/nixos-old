
{ config, pkgs, lib, ... }:

with lib;

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    arosenfeld = {
      isNormalUser = true;
      extraGroups = [ "wheel" "media" ]; # Enable ‘sudo’ for the user.
    };
    camille = {
      uid = 1001;
      isNormalUser = true;
      extraGroups = [ "media" ];
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