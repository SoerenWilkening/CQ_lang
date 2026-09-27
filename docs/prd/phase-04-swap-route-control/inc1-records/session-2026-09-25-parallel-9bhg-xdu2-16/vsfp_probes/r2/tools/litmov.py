#!/usr/bin/env python3
"""litmov.py ABFILE : split the lit movers of an ab.py file into fixtures this branch
touched (round 1 vs main, or round 2 working tree) and fixtures it did NOT touch."""
import pathlib
import sys

V = pathlib.Path(__file__).parent
own = set()
for l in (V / "st_now.txt").read_text().splitlines():
    own.add(l[3:].split(" -> ")[-1].replace("ir-pass/test/", ""))
for l in (V / "st_r1.txt").read_text().splitlines():
    own.add(l.replace("ir-pass/test/", ""))
rows = [l.split("\t") for l in open(sys.argv[1]) if "/ir-pass/test/" in l]
for k, path, *rest in rows:
    n = path.split("/")[-1]
    print(("OWN" if n in own else "UNTOUCHED"), k, n)
