#!/usr/bin/env python3
"""Dump ONE twin-matrix cell's rolled and flat C sources, so a single cell can
be attributed across binaries without re-running the 338-cell matrix."""
import sys, importlib.util, os
spec = importlib.util.spec_from_file_location("ltm", "tools/loop_twin_matrix.py")
m = importlib.util.module_from_spec(spec)
sys.argv = ["ltm"]           # keep its argparse out of the way
spec.loader.exec_module(m)
want = sys.argv[1] if len(sys.argv) > 1 else None
