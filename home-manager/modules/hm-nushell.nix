{ config, lib, pkgs, ... }:

{

  programs.nushell = {
    enable = true;
    # The config.nu can be anywhere you want if you like to edit your Nushell with Nu
    # configFile.source = ./.../config.nu;
    # # for editing directly to config.nu
    # extraConfig = ''
    #   let carapace_completer = {|spans|
    #   carapace $spans.0 nushell ...$spans | from json
    #   }
    #   $env.config = {
    #    show_banner: false,
    #    completions: {
    #    case_sensitive: false # case-sensitive completions
    #    quick: true    # set to false to prevent auto-selecting completions
    #    partial: true    # set to false to prevent partial filling of the prompt
    #    algorithm: "fuzzy"    # prefix or fuzzy
    #    external: {
    #    # set to false to prevent nushell looking into $env.PATH to find more suggestions
    #        enable: true
    #    # set to lower can improve completion performance at the cost of omitting some options
    #        max_results: 100
    #        completer: $carapace_completer # check 'carapace_completer'
    #      }
    #    }
    #   }
    #   $env.PATH = ($env.PATH |
    #   split row (char esep) |
    #   prepend /home/myuser/.apps |
    #   append /usr/bin/env
    #   )
    # '';
    # shellAliases = {
    #   vi = "hx";
    #   vim = "hx";
    #   nano = "hx";
    # };
  };
    
  programs.carapace.enableNushellIntegration = true;

  home.packages = with pkgs; [

    ## Official nushell plugins available in nixpkgs-unstable
    nushellPlugins.semver
    nushellPlugins.query        # SQL-like query support
    nushellPlugins.highlight    # syntax highlighting
    nushellPlugins.units
    nushellPlugins.polars       # DataFrame support via Polars (super powerful)
    nushellPlugins.gstat        # git plugin
    nushellPlugins.formats
  ];

}
