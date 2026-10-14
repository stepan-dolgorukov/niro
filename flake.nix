{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "corefonts";
      };
      tex = pkgs.texliveSmall;
      templates = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.fileFilter (file: file.hasExt "tex") ./.;
      };
      docs = [ "assignment/assignment" "review/review" "report/report" ];
      compile = pkgs.writeShellScriptBin "compile.sh" ''
        set -e
        docs=("$@")
        [ $# -eq 0 ] && docs=(${nixpkgs.lib.escapeShellArgs docs})
        for doc in "''${docs[@]}"; do
          for pass in 1 2; do
            ${tex}/bin/xelatex -interaction=nonstopmode -halt-on-error "''${doc%.tex}.tex"
          done
        done
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ tex pkgs.texstudio compile ];
        TEX_TEMPLATES = templates;
        FONTCONFIG_FILE = pkgs.makeFontsConf {
          fontDirectories = [ pkgs.corefonts ];
        };
      };
    };
}
