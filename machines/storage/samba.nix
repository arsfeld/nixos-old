
{ config, pkgs, lib, ... }:

with lib;

{
  services.samba = {
    enable = true;
    enableNmbd = true;
    syncPasswordsByPam = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP

      browseable = yes
      ;hosts allow = 192.168.1.0/24
      map archive = no
      ; Maybe this should be done per share. Taken from:
      ; https://wiki.samba.org/index.php/Setting_up_a_Share_Using_Windows_ACLs
      vfs objects = acl_xattr
      map acl inherit = yes
      allow insecure wide links = yes
      writable = yes
    '';
    shares = {
      Files = {
        path = "/mnt/data/files";
        browseable = "yes";
      };

      Media = {
        path = "/mnt/data/media";
        browseable = "yes"; 
      };

      Backups = {
        path = "/mnt/data/backups"; 
        browseable = "yes";
      };

      Camera = {
        path = "/mnt/data/camera"; 
        browseable = "yes";
        public = "yes";
      };

      homes = {
        "follow symlinks" = "yes";
        "wide links" = "yes";
        browseable = "yes";
      };
    };
  };

}
