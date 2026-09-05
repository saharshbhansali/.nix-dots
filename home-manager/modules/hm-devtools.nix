{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  ## User level packages
  home.packages = with pkgs; [
    # Omnix: improved DevEx on nixos - https://omnix.page
    omnix

    # ## VS Code
    vscode-fhs
    # vscodium
    # (vscode-with-extensions.override {
    #   vscodeExtensions = with vscode-extensions; [
    #     github.copilot
    #     github.copilot-chat
    #     supermaven.supermaven
    #     tabnine.tabnine-vscode
    #
    #     ms-azuretools.vscode-docker
    #
    #     bbenoist.nix
    #     ms-python.python
    #     ms-python.debugpy
    #
    #     # catppuccin.cattppuccin-vscode
    #   ];
    # })

    # ## Helix editor
    helix
    # evil-helix
    # helix-gpt

    ## AI editors
    # code-cursor
    code-cursor-fhs
    devin-desktop # formerly: windsurf
    # zed-editor
    zed-editor-fhs

    # AI code assistant
    opencode
    claude-code
    gpt-cli
    # aider-chat
    aider-chat-full
    cursor-cli

    # AWS CLI
    awscli2
  ];
}
