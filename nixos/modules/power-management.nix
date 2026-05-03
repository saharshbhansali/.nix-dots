{ config, lib, pkgs, ... }:

{

  # one of "ignore", "poweroff", "reboot", "halt", "kexec", "suspend", "hibernate", "hybrid-sleep", "suspend-then-hibernate", "lock"
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";  # Battery: S3 → S4 after 30min
    HandleLidSwitchExternalPower = "lock";       # AC: lock only
    HandleLidSwitchDocked = "lock";              # Docked: lock only
    PowerKey = "suspend";                        # Power key: suspend (becomes hybrid-sleep)
  };

  # Configure sleep modes
  systemd.sleep.settings.Sleep = {
    AllowHybridSleep = true;              # Enable hybrid-sleep mode (power key on AC/docked)
    AllowSuspendThenHibernate = true;     # Enable suspend-then-hibernate (battery lid close)
    HibernateDelaySec = 1800;             # 30 minutes before hibernating (battery mode)
    SuspendState = "mem";                 # Deep sleep (s3) when suspending
  };

  # Kernel parameter for deep sleep
  boot.kernelParams = [
    "mem_sleep_default=deep"  # Use deep sleep (s3) as default suspend mode
  ];

  powerManagement.powertop.enable = true; # enable powertop auto tuning on startup.

  services.system76-scheduler.settings.cfsProfiles.enable = true; # Better scheduling for CPU cycles - thanks System76!!!
  services.power-profiles-daemon.enable = false; # Disable GNOMEs power management

  services.tlp = {
    enable = true; # Enable TLP (better than gnomes internal power manager)
    settings = {
      # CPU performance mode (AC power)
      CPU_BOOST_ON_AC = 1;
      CPU_MAX_PERF_ON_AC = 100;      # Maximum CPU performance on AC
      CPU_MIN_PERF_ON_AC = 20;       # Minimum CPU performance on AC
      CPU_BOOST_ON_BAT = 1;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      # Disable aggressive power saving on AC (desktop performance mode)
      SATA_LINKPWR_ON_AC = "max_performance";  # Full SATA performance
      WIFI_PWR_ON_AC = "off";                  # Disable WiFi power saving
      PCIE_ASPM_ON_AC = "performance";         # PCIe performance mode

      # USB autosuspend: disabled on AC, aggressive on battery
      USB_AUTOSUSPEND = 1;                     # Enable feature
      USB_BLACKLIST = "*";                     # Blacklist all on AC
      USB_AUTOSUSPEND_ON_AC = 0;               # Disabled on AC (no lag)
      USB_AUTOSUSPEND_ON_BAT = 1;              # Aggressive on battery (save power)

      # Disable disk power management (desktops don't need it)
      DISK_DEVICES = "none";

      # Battery charging thresholds (laptop-specific)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 85;
    };
  };

  # services.auto-cpufreq.enable = true;
  # services.auto-cpufreq.settings = {
  #   battery.governor = "powersave";
  #   battery.turbo = "never";
  #
  #   charger.governor = "powersave";
  #   charger.turbo = "never";
  # };

  ## Gaming specialization: disable power management for max performance
  # NOTE: Hibernate (S4) saves system state - resume must use same specialization
  specialisation = {
    gaming.configuration = {
      # Gaming mode: longer hibernate delay (1.5 hours) for mid-game pauses
      systemd.sleep.settings.Sleep.HibernateDelaySec = lib.mkForce 1200;  # 20 minutes
    };
  };

}
