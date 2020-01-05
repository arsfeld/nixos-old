
{ config, pkgs, lib, ... }:

with lib;

{
  services.samba = {
    enable = false;
    enableNmbd = true;
    syncPasswordsByPam = true;
    securityType = "user";
    extraConfig = ''
      hosts allow = 192.168.1.0/24
      map archive = no
      ; Maybe this should be done per share. Taken from:
      ; https://wiki.samba.org/index.php/Setting_up_a_Share_Using_Windows_ACLs
      vfs objects = acl_xattr
      map acl inherit = yes
    '';
    shares = {
      Files = {
        path = "/mnt/data/files";
        browseable = "yes";
      };

      users = {
        path = "/mnt/data/homes";
        "read only" = "no";
        "force create mode" = "0600";
        "force directory mode" = "0700";
      };

      #Camera = {
      #  path = "/mnt/data/camera";
      #  
      #}
    };
  };

}