{ config, pkgs, ... }:

{
  imports =
    [ 
      ../../modules/common.nix
      ./hardware-configuration.nix
      ./zfs.nix
      ./apps.nix
      ./samba.nix
      ./users.nix
      ./backup.nix
    ];

  zramSwap.algorithm = "zstd";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "storage"; # Define your hostname.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.firewall.enable = false;
  networking.hostId = "d5325dbe";
  networking.wireguard.enable = true;

  services.fail2ban.enable = true;

  programs.zsh.enable = true;

  # Enable Oh-my-zsh
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "sudo" "docker" "kubectl" ];
  };

  programs.command-not-found.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

