{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "if";

          packages = [
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
          ];

          shellHook = ''
            export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
            export PS1="($name)\n$PS1"

            f () {
              elm-format "$PROJECT_ROOT/src" "''${@:---yes}"
            }

            c () {
              nix flake check -L &&
              f --validate
            }

            clean () {
              rm -rf "$PROJECT_ROOT/elm-stuff"
            }

            echo "Development environment loaded"
            echo ""
            echo "Type 'f' to run elm-format"
            echo "Type 'c' to run all checks"
            echo "Type 'clean' to remove build artifacts"
            echo ""
          '';
        };
      }
    );
}
