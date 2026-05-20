// P0 driver: print help and exit 0. Real argument parsing arrives in a
// later phase together with clang::tooling::CommonOptionsParser.
#include <cstdio>

static void printHelp() {
    std::printf(
        "quantum_transpiler v0 - usage: quantum_transpiler <file.c> -- "
        "[clang args]\n"
        "  --help, -h    show this message\n");
}

int main(int /*argc*/, char ** /*argv*/) {
    // P0 is a smoke test only: every invocation (including --help / -h)
    // prints the help text and exits successfully.
    printHelp();
    return 0;
}
