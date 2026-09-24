#!/usr/bin/env python3
import ast, re, pathlib, sys
log = pathlib.Path(__file__).parent / sys.argv[1]
lines = log.read_text().splitlines()
for l in lines:
    if l.startswith("NULL") or l.startswith("A/B"):
        print(l)
movers = [ast.literal_eval(l.strip()) for l in lines if l.strip().startswith("(")]
names = sorted({re.sub(r"^probes\d__", "", m[0]).replace(".s1.ll", "").replace(".bank", "") for m in movers})
print("unique programs:", len(names), "directions:", sorted({(m[1], m[2]) for m in movers}))
for n in names:
    print("  ", n)
