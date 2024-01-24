{ config
, lib
, pkgs
, ...}:
let
  removeStrSpaces = string: lib.concatStrings (lib.filter (s: s != " ") (lib.stringToCharacters string));
in
{
  config = lib.mkIf (config.sbc.bootstrap.enable && config.sbc.bootstrap.initialBootstrapImage) {
    environment.systemPackages = with pkgs; [
      # Provide git by default as it is required to work with flakes.
      git
    ];

    networking.hostName = removeStrSpaces config.sbc.board.name;

    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    users = {
      motd = ''
        Welcome to the bootstrap image, if you have not yet changed the users
        password, do so immediately with the "passwd" command.
      '';
      users.root = {
        password = "SBCDefaultBootstrapPassword";
      };
    };
  };
}
