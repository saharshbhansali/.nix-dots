{
  config,
  pkgs,
  ...
} @ args: let
  inherit (args) username;
  homeDir = "${config.users.users.${username}.home}";
in {
  environment.systemPackages = with pkgs; [
    age
    sops
    ssh-to-age
    git-crypt
  ];

  sops = {
    # This will add secrets.yml to the nix store
    # You can avoid this by adding a string to the full path instead, i.e.
    # defaultSopsFile = "/root/.sops/secrets/example.yaml";
    defaultSopsFile = ../../secrets/secrets.yaml;

    age = {
      # This will automatically import SSH keys as age keys
      sshKeyPaths = ["${homeDir}/.ssh/saharshbhansali"];
      # This is using an age key that is expected to already be in the filesystem
      keyFile = "${homeDir}/.config/sops/age/keys.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
    };

    # # This is the actual specification of the secrets.
    # secrets = {
    #   example-key = {};
    #   "myservice/my_subdir/my_secret" = {};
    # };
  };
}
