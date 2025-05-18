{ pkgs, config, lib, ... }:

{

  # SDDM - set package and theme
  # # services.displayManager.sddm.package = lib.mkForce pkgs.kdePackages.sddm;
  # services.displayManager.sddm.package = lib.mkForce pkgs.libsForQt5.sddm;
  # # services.displayManager.sddm.theme = lib.mkForce "where-is-my-sddm-theme";
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.theme = lib.mkForce "where-is-my-sddm-theme";
  services.displayManager.sddm.autoNumlock = true;
  # # Enable numlock on startup
  # services.xserver.displayManager.setupCommands = "${pkgs.numlockx}/bin/numlockx on";
  # systemd.services.numlock = {
  #   description = "Enable NumLock at startup";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #     ExecStart = "${pkgs.numlockx}/bin/numlockx on";
  #   };
  # };

}
