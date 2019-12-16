{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;


  programs.git = {
    enable = true;
    userName = "Alexandre Rosenfeld";
    userEmail = "arsfeld@gmail.com";
  };

  home.packages = with pkgs; [
    killall
    htop
    unstable.jetbrains.pycharm-community
    sublime3
    sublime-merge

    zsh-prezto    
    ncdu # Disk space usage analyzer
    ripgrep # rg, fast grepper
    unstable.vscode
    rtv
    unstable.zoom-us
    unstable.slack
    youtube-dl
  ];
  
  programs = {
    command-not-found.enable = true;
    
    zsh.enable = true;
  };
}
