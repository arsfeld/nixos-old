# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  hardware = import <nixos-hardware> {};
  unstable = import <nixos-unstable> {};
in {
  imports = 
    [ # Include the results of the hardware scan. 
      <nixos-hardware/common/cpu/intel>
      <nixos-hardware/common/pc/laptop>
      <nixos-hardware/common/pc/laptop/ssd>
      ./hardware-configuration.nix
    ];

  nixpkgs.config = {
    # Allow proprietary packages
    allowUnfree = true;
  
    # Create an alias for the unstable channel
    packageOverrides = pkgs: {
      # unstable = import <nixos-unstable> {
      #   # pass the nixpkgs config to the unstable alias
      #   # to ensure `allowUnfree = true;` is propagated:
      #   config = config.nixpkgs.config;
      # };

      #vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };  
  };

  # environment.variables = {
  #   MESA_LOADER_DRIVER_OVERRIDE = "iris";
  # };
  
  # hardware.opengl = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     vaapiIntel
  #     vaapiVdpau
  #     libvdpau-va-gl
  #     intel-media-driver # only available starting nixos-19.03 or the current nixos-unstable
  #   ];
  #   package = (pkgs.mesa.override {
  #     galliumDrivers = [ "nouveau" "virgl" "swrast" "iris" ];
  #   }).drivers;
  # };

  services.udev.extraRules = ''
    # set deadline scheduler for non-rotating disks
    # according to https://wiki.debian.org/SSDOptimization, deadline is preferred over noop
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
    # https://support.google.com/titansecuritykey/answer/9148044?hl=en
    ACTION=="add|change", KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="5026", TAG+="uaccess"
  '';

  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    cue = true;
  }; 

  #boot.kernelParams = [ "i915.fastboot=1" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.supportedFilesystems = [ "f2fs" ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.autoOptimiseStore = true;

  #boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  networking.hostName = "nixos"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  #networking.interfaces.wlp1s0.useDHCP = true;

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
    wget vim gnupg git usbutils
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:
  services.flatpak.enable = true;
  services.fwupd.enable = true;

  virtualisation.lxd.enable = true;
  virtualisation.docker.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.resolved.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.u2f.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.desktopManager.gnome3.enable = true;
  services.gnome3.core-os-services.enable = true;

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.arosenfeld = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "lxd" ]; # Enable ‘sudo’ for the user.
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

