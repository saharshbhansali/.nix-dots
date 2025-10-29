{ config, lib, pkgs, ... }:

{

  # Networking services
  networking.hostName = "nixos";
  networking.wireless.enable = false;

  # Network Manager
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none"; # prevent DHCP DNS override

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

  ## Systemd resolved configuration
  networking.nameservers = [
    ## IPv4 DNS servers
    # Mullvad - adblock.dns.mullvad.net
    "194.242.2.3"
    # AdGuard - dns.adguard-dns.com
    "94.140.14.14"
    # LibreDNS no ads
    "116.202.176.26#noads.libredns.gr"
    ## IPv6 DNS servers
    # Mullvad - adblock.dns.mullvad.net
    "2a07:e340::3"
    # AdGuard - dns.adguard-dns.com
    "2a10:50c0::ad1:ff"
    # LibreDNS no ads
    "2a01:4f8:1c0c:8274::1#noads.libredns.gr"
  ];

  services.dnsproxy = {
    enable = true;

    settings = {
      # Listen locally on the default DNS port
      listen-addrs = [
        "127.0.0.1"
        "0.0.0.0"
      ];
      # listen-ports = [ "53" ];

      # === Upstream servers ===
      # LibreDNS adblocking over DoT, DoH, and DoQ
      upstream = [
        # DNS-over-TLS
        "tls://noads.libredns.gr"

        # DNS-over-HTTPS
        "https://doh.libredns.gr/noads"

        # DNS-over-QUIC (UDP/784)
        "quic://noads.libredns.gr"
      ];

      # === Bootstrap resolver ===
      # Used to resolve the LibreDNS domain initially
      bootstrap = [
        "1.1.1.1"
        "8.8.8.8"
        "116.202.176.26"
      ];

      # === Fallback plaintext DNS (used only if all encrypted fail) ===
      fallback = [
        ## IPv4 DNS servers
        # Cloudflare - 1.1.1.1
        "1.1.1.1"
        # Google - 8.8.8.8
        "8.8.8.8"
        ## IPv6 DNS servers
        # Cloudflare - 1.1.1.1
        "2606:4700:4700::1111"
        # Google - 8.8.8.8
        "2001:4860:4860::8888"
      ];

      # === Timeouts/Faliures ===
      timeout = "5s";
      max-fails = 3;

      # === Performance / behavior options ===
      cache = true;
      cache-size = 4096;        # entries
      all-servers = false;      # query one upstream at a time
      ipv6-disabled = false;    # disable IPv6 if you don't use it

      # === Logging ===
      log-queries = false;
      verbose = false;
    };

  };

  systemd.services.dnsproxy = {
    after = [ "network.target" ];
    wants = [ "network.target" ];
  };

  ## Fix broken captive portal detection
  programs.captive-browser.enable = true;
  # hardcoded interface name, bypass with:
  ## captive-browser --interface $(ip route | awk '/default/ {print $5; exit}')
  programs.captive-browser.interface = "wlo1";

}

