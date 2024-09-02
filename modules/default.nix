{
  default = {
    imports = [
      ./sbc
    ];
  };

  boards = import ./boards;
  cache = import ./cache.nix;
}
