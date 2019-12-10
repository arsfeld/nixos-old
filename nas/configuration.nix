# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s4.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    samba 
    wget 
    vim 
    git 
    restic
  ];

  virtualisation.docker.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.restic.backups = {
    localbackup = {
      paths = [ "/mnt/data/homes" ];
      repository = "/mnt/external/restic";
      passwordFile = "/etc/nixos/secrets/restic-password";
      initialize = true;
    };
  };

  services.samba = {
    enable = true;
    enableNmbd = true;
    syncPasswordsByPam = true;
    #package = pkgs.samba4;
    extraConfig = ''
      workgroup = WORKGROUP
      server string = nixos
      netbios name = nixos
      security = user
      guest account = nobody
      map to guest = bad user
      hosts allow = 192.168.1.0/24
    '';

    shares = {
      Files = {
        path = "/mnt/data/files";
        browseable = "yes";
      };

      homes = {
        "read only" = "no";
        browseable = "no";
      };
    };

    #Camera = {
    #  path = "/mnt/data/camera";
    #  
    #}
  };

  services.netdata = {
    enable = true;

    config = {
      global = {
        "debug log" = "syslog";
        "access log" = "syslog";
        "error log" = "syslog";
      };
    };
  };

  fileSystems = 
    let 
      makeNfsShare = name:
        {
          mountPoint = name;
          device = "192.168.1.10:" + name;
          fsType = "nfs";
          options = [ "rw" "local_lock=all" ];
        };
    in
      map makeNfsShare [ "/mnt/data/files" "/mnt/data/media" "/mnt/data/homes" "/mnt/external" ];

  # Open ports in the firewall.
  networking.firewall.enable = false;
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [ 
    22 #ssh 
    19999 #netdata 
    445 # samba
  ];
  networking.firewall.allowedTCPPortRanges = [
    { from = 137;  to = 139; }   # Samba
  ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.arosenfeld = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

