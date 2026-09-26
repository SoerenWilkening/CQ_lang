#!/usr/bin/env python3
"""showfn.py FILE [FN...]: print the named function bodies (default: all defines)."""
import re
import sys

txt = open(sys.argv[1]).read()
want = set(sys.argv[2:])
for m in re.finditer(r"^define [^\n]*@([\w.]+)\([^\n]*\{\n.*?^\}", txt, re.S | re.M):
    if not want or m.group(1) in want:
        print(m.group(0))
