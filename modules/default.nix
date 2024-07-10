{
  default = {
    imports = [
      ./sbc
    ];
  };

  boards = import ./boards;

  _support = {
    flakeCi = import ../lib/flake-ci/module.nix;
  };
}
