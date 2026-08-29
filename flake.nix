{
  description = "Zig project flake";

  inputs = {
    zig2nix.url = "github:Cloudef/zig2nix";
    fenix.url = "github:nix-community/fenix";
  };

  outputs = { zig2nix, fenix, ... }: let
    flake-utils = zig2nix.inputs.flake-utils;
  in (flake-utils.lib.eachDefaultSystem (system: let
      # Zig flake helper
      # Check the flake.nix in zig2nix project for more options:
      # <https://github.com/Cloudef/zig2nix/blob/master/flake.nix>
      env = zig2nix.outputs.zig-env.${system} { zig = zig2nix.outputs.packages.${system}.zig-0_16_0; };

      # nixpkgs does not provide rust with rust-src, so that can't cross-compile
      rust = fenix.packages.${system}.complete.withComponents [
        "cargo"
        "rustc"
        "rust-src"
      ];
    in {
      # nix run .
      apps.default = env.app [] ''zig build run -- "$@"'';

      # nix run .#build
      apps.build = env.app [] ''zig build "$@"'';

      # nix run .#bench
      apps.bench = env.app [rust] ''bash bench.sh "$@"'';

      # nix develop
      devShells.default = env.mkShell {};
    }));
}
