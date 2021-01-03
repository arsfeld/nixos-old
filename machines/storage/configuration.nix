{ config, pkgs, ... }:

{
  imports = [
    ../../modules/common.nix
    ./hardware-configuration.nix
    ./zfs.nix
    ./services.nix
    ./docker.nix
    ./samba.nix
    ./users.nix
    ./backup.nix
  ];

  zramSwap.algorithm = "zstd";

  boot = { kernel.sysctl = { "fs.inotify.max_user_watches" = "1048576"; }; };

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;

  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  networking.hostName = "storage"; # Define your hostname.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  # networking.firewall.enable = false;
  networking.hostId = "d5325dbe";
  networking.wireguard.enable = false;

  services.fail2ban.enable = true;

  networking.firewall = {
    allowedTCPPorts = [ 80 443 22000 32400 3005 8324 32469 ]; 
    allowedUDPPorts = [ 21027 1900 5353 32410 32412 32413 32414 ];
  };

  programs.zsh.enable = true;

  # Enable Oh-my-zsh
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "sudo" "docker" "kubectl" ];
  };

  programs.command-not-found.enable = true;

  nix.gc = {
     automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

