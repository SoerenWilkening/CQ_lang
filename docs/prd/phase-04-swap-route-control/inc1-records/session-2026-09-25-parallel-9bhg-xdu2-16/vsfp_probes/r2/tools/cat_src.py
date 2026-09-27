#!/usr/bin/env python3
"""cat_src.py DIR NAME... : print each probe's caller (minus #includes) and lib."""
import pathlib
import sys

d = pathlib.Path(sys.argv[1])
for n in sys.argv[2:]:
    print(f"== {n}")
    c = d / f"{n}.c"
    if c.exists():
        print("\n".join(l for l in c.read_text().splitlines() if not l.startswith("#include")))
    lib = d / f"{n}.lib.c"
    if lib.exists():
        print("-- lib")
        print(lib.read_text().rstrip())
