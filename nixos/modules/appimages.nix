{ pkgs, nixpkgs, lib, config, ... }:

{

  ## AppImages
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: with pkgs; [
        icu
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    appimage-run
  ];

}

