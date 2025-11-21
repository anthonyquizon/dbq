with (import <nixpkgs> {});
mkShell {
  buildInputs = [
    cbqn-replxx
    picosat

    # testing
    python312
    python312Packages.pycosat
  ];
}
