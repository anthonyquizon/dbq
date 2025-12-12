
case "$(uname -s)" in
    Linux*)  gcc -shared src/lib.c -o cbits/lib.so ;;
    Darwin*) clang -shared cbits/lib.c -framework CoreServices -o cbits/lib.so ;;
esac

# TODO picosat
