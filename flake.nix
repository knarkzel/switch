{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
    packages.x86_64-linux.default = {
      devShell = pkgs.mkShell {
        shellHook = ''
          export DEVKITPRO=hello
        '';
      };
    };
  };
}
