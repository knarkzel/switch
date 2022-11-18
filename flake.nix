{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    devkitnix = {
      url = "github:knarkzel/devkitnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    devkitnix,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
    devkitA64 = devkitnix.packages.x86_64-linux.devkitA64;
    libc = pkgs.writeText "libc.txt" ''
      include_dir=${devkitA64}/devkitA64/aarch64-none-elf/include
      sys_include_dir=${devkitA64}/devkitA64/aarch64-none-elf/include
      crt_dir=${devkitA64}/devkitA64/lib
      msvc_lib_dir=
      kernel32_lib_dir=
      gcc_dir=
    '';
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [
        pkgs.zig
        pkgs.ryujinx
        devkitA64
      ];
      shellHook = ''
        export LIBC=${libc}
        export DEVKITPRO=${devkitA64}
      '';
    };
  };
}
