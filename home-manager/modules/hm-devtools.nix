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

    ## Code editors
    # code-cursor
    code-cursor-fhs
    # zed-editor
    zed-editor-fhs

    # AI tooling
    docker-sbx
    # inputs.hermes-agent.packages.${stdenv.hostPlatform.system}.default
    chatgpt
    opencode
    opencode-desktop
    claude-code
    cursor-cli
    # devin-desktop # formerly: windsurf
    # gpt-cli
    # vimPlugins.opencode-nvim
    # vimPlugins.claudecode-nvim
    # aider-chat
    # aider-chat-full
    # cmux
    herdr

    # AWS CLI
    awscli2

    # Package management and audit
    inputs.perplexityai-bumblebee.packages.${stdenv.hostPlatform.system}.default
  ];
}
