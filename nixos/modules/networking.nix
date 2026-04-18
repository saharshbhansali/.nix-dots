{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasIPv6Internet = true;
  StateDirectory = "dnscrypt-proxy";
in
{
  # Turn off PCIe ASPM
  # boot.kernelParams = [ "pcie_aspm=off" ];
  boot.extraModprobeConfig = ''
    options rtw89_pci disable_clkreq=1 disable_aspm_l1=1 disable_aspm_l1ss=1
    options rtw89_core disable_ps_mode=1
  '';

  # Networking services
  networking.hostName = "nixos";
  networking.wireless.enable = lib.mkDefault false;

  # Network Manager
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none"; # prevent DHCP DNS override
  networking.networkmanager.wifi.powersave = false;

  users.users.saharsh.extraGroups = lib.mkAfter [ "networkmanager" ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.docker0.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp5s0f4u1.useDHCP = lib.mkDefault true;

  # Set DNS nameservers statically and make sure that network manager won't override set nameservers with some random settings it received over DHCP
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];
  networking.dhcpcd.extraConfig = "nohook resolv.conf";

  networking.resolvconf.enable = pkgs.lib.mkForce false;
  services.resolved.enable = false;

  # See https://wiki.nixos.org/wiki/Encrypted_DNS
  services.dnscrypt-proxy = {
    enable = true;
    # See https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
    settings = {
      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        cache_file = "/var/lib/${StateDirectory}/public-resolvers.md";
      };

      # static = [
      #   {
      #     myserver.name = {
      #       # Calculate stamp from: https://dnscrypt.info/stamps/
      #       stamp = "";
      #     };
      #   }
      # ];

      # Use servers reachable over IPv6 -- Do not enable if you don't have IPv6 connectivity
      ipv6_servers = hasIPv6Internet;
      block_ipv6 = !(hasIPv6Internet);

      require_dnssec = false;
      require_nolog = false;
      require_nofilter = true;

      server_names = [
        "libredns-noads"
        "adguard-dns-doh"
        "mullvad-adblock-doh"
        "quad9-dnscrypt-ip4-filter-ecs-pri"
        "controld-block-malware-ad"
      ];
    };
  };

  systemd.services.dnscrypt-proxy.serviceConfig.StateDirectory = StateDirectory;

  ## Fix broken captive portal detection
  programs.captive-browser.enable = true;
  # hardcoded interface name, bypass with:
  ## captive-browser --interface $(ip route | awk '/default/ {print $5; exit}')
  programs.captive-browser.interface = "wlo1";

  # Enable the WARP daemon
  services.cloudflare-warp.enable = true;

  # ## Temporary fix (disable autoconnect) for broken Realtek PCI WiFi card
  # systemd.services."disable-wlo1-on-boot" = {
  #   description = "disable wlo1 on boot (nmcli)";
  #   after = [ "NetworkManager-wait-online.service" ];
  #   wants = [ "NetworkManager-wait-online.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     # ExecStart = "${pkgs.networkmanager}/bin/nmcli device set wlo1 autoconnect no";
  #     # ExecStart = "${pkgs.networkmanager}/bin/nmcli device disconnect wlo1";
  #     ExecStart = "${pkgs.networkmanager}/bin/nmcli device down wlo1";
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  # };

  # networking.networkmanager.settings = {
  #   # under the [connection-wifi-wlo1] section
  #   connection-wifi-wlo1."match-device" = "interface-name:wlo1";
  #   connection-wifi-wlo1."connection.auth-retries" = 1;
  #   connection-wifi-wlo1."connection.autoconnect" = "no";
  #   connection-wifi-wlo1."connection.autoconnect-priority" = -100;
  #   connection-wifi-wlo1."connection.autoconnect-retries" = 1;
  # };

  # ## Unmanage wlo1 interface
  # networking.networkmanager.unmanaged = [ "wlo1" ];

  ## User systemd service to disable-wifi-on-login
  systemd.user.services.disable-wifi-on-login = {
    enable = true;
    description = "disable WiFi interface wlo1 after graphical login";
    # Ensure it runs after the graphical session has started
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    # after = [ "network-online.target" ];
    # wantedBy = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      # Small delay to let NetworkManager recognize wlo1 before running nmcli
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      # ExecStart = "${pkgs.networkmanager}/bin/nmcli device down wlo1";
      ExecStart = "${pkgs.networkmanager}/bin/nmcli device set wlo1 autoconnect no";
      # ExecStart = "${pkgs.networkmanager}/bin/nmcli device set wlo1 managed no";
    };
  };

  # udev rule to modeswitch external usb wifi dongle
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="1a2b", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -KW -v 0bda -p 1a2b"
  '';

}
