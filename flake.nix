{
  description = "Evidence-led Common Lisp reconstruction of IntelliCorp KEE";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems
        (system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          {
            default = pkgs.mkShell {
              packages = with pkgs; [
                graphviz
                imagemagick
                nodejs
                perl
                playwright-driver.browsers
                playwright-test
                sbcl
              ];
            };
          });
    };
}
