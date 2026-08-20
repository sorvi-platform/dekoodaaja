{
  description = "Zig project flake";

  inputs = {
    zig2nix.url = "github:Cloudef/zig2nix";
  };

  outputs = { zig2nix, ... }: let
    flake-utils = zig2nix.inputs.flake-utils;
  in (flake-utils.lib.eachDefaultSystem (system: let
      # Zig flake helper
      # Check the flake.nix in zig2nix project for more options:
      # <https://github.com/Cloudef/zig2nix/blob/master/flake.nix>
      env = zig2nix.outputs.zig-env.${system} { zig = zig2nix.outputs.packages.${system}.zig-0_16_0; };
    in {
      # nix run .
      apps.default = env.app [] ''zig build run -- "$@"'';

      # nix run .#build
      apps.build = env.app [] ''zig build "$@"'';

      # nix run .#bench
      apps.bench = with env.pkgs; env.app [cargo] ''bash bench.sh "$@"'';

      # nix develop
      devShells.default = env.mkShell {};
    }));
}
