{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Workaround to improve performance by flattening XDG_DATA_DIRS into a single directory
  # Ref: https://github.com/NixOS/nixpkgs/issues/126590#issuecomment-2860616947
  plasmashell-workaround = final: prev: {
    kdePackages =
      prev.kdePackages
      // {
        plasma-workspace = let
          basePkg = prev.kdePackages.plasma-workspace;
        in
          pkgs.stdenv.mkDerivation {
            inherit (basePkg) sessions;

            name = "plasma-workspace";
            buildInputs = [basePkg];
            dontUnpack = true;
            dontWrapQtApps = true;
            installPhase = ''

              # remove duplicates in XDG_DATA_DIRS to speed up the copy process
              export XDG_DATA_DIRS="$(awk -v RS=: '{ if (!arr[$0]++) { printf("%s%s", !ln++ ? "" : ":", $0) }}' <<< "$XDG_DATA_DIRS")"

              # copy output from base package and make it writable
              mkdir -p $out && cp -r ${basePkg}/. $out/
              chmod u+w $out $out/bin $out/bin/plasmashell

              # copy all XDG_DATA_DIRS into a single directory
              ( IFS=:
                mkdir $out/xdgdata
                for DIR in $XDG_DATA_DIRS; do
                  if [[ -d "$DIR" ]]; then
                    cp -r $DIR/. $out/xdgdata/
                    chmod -R u+w $out/xdgdata
                  fi
                done
              )

              # create a wrapper script that replaces the original XDG_DATA_DIRS with the
              # newly created directory and then calls the original plasmashell binary
              cat << EOF > $out/bin/plasmashell
              #!/bin/sh
              export XDG_DATA_DIRS=$out/xdgdata:/run/current-system/sw/share
              exec ${basePkg}/bin/.plasmashell-wrapped "\$@"
              EOF
              chmod a+x $out/bin/plasmashell
            '';

            passthru.providedSessions = basePkg.passthru.providedSessions;
          };
      };
  };
in {
  nixpkgs.overlays = [plasmashell-workaround];

  # imports = [
  #   ./sddm.nix
  # ];

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
  };
  xdg.portal.config.common.default = "*";

  # KDE Plasma
  services.desktopManager.plasma6.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.krohnkite
    kdePackages.plasma-browser-integration
    kdePackages.kdeconnect-kde
    kdePackages.kdbusaddons
    kontainer
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
  ];
}
