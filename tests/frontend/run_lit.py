#!/usr/bin/env python3
"""Run the CQ frontend LIT suite, tolerating an empty suite.

The bundled lit shipped with LLVM 19 (lit 19.1.7) has no ``--allow-empty-suite``
flag, and ``--allow-empty-runs`` only suppresses the *filter-matched-nothing*
error, not the *discovered-nothing* error (``main.py`` exits 2 before any
filtering when discovery comes up empty). The frontend scaffold deliberately
lands with ZERO ``*.c`` fixtures (the first arrives in a later milestone), so a
bare lit run would exit non-zero and break ``ctest``.

This wrapper forwards to lit unchanged in every respect EXCEPT one: if lit exits
non-zero solely because it discovered no tests, we rewrite that to success. Any
other non-zero exit (a real test failure, a config error, a bad argument) is
propagated verbatim. lit still discovers ``*.c`` files dynamically at run time,
so the moment a fixture lands this wrapper runs it with no re-configure needed.

Usage:
    run_lit.py <python> <lit.py> [lit args...] <test-dir>

The first two positional arguments are the Python interpreter and the lit.py
script resolved by CMake; the remainder is passed straight through to lit.
"""

import subprocess
import sys

# Sentinel emitted on stderr by lit's main.py when discovery finds no tests.
_EMPTY_SUITE_SENTINEL = "did not discover any tests for provided path(s)"


def main(argv):
    if len(argv) < 3:
        sys.stderr.write(
            "run_lit.py: expected <python> <lit.py> [args...] <test-dir>\n"
        )
        return 2

    lit_cmd = argv[1:]

    # Stream lit's stdout straight through; capture stderr so we can inspect it
    # for the empty-suite sentinel while still echoing it to the real stderr.
    proc = subprocess.run(lit_cmd, stderr=subprocess.PIPE, text=True)
    if proc.stderr:
        sys.stderr.write(proc.stderr)

    if proc.returncode != 0 and _EMPTY_SUITE_SENTINEL in (proc.stderr or ""):
        sys.stderr.write(
            "run_lit.py: empty suite (no *.c fixtures yet) — treating as success\n"
        )
        return 0

    return proc.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv))
