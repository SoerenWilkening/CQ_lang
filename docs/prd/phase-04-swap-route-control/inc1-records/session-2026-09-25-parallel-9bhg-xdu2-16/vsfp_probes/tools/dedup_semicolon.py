#!/usr/bin/env python3
"""Collapse the doubled `;` line the re-spell note introduced after its last line."""
import pathlib
import sys

n = 0
for f in sys.argv[1:]:
    p = pathlib.Path(f)
    s = p.read_text()
    s2 = s.replace("(CLAUDE.md L8).\n;\n;\n", "(CLAUDE.md L8).\n;\n", 1)
    if s2 != s:
        n += 1
        p.write_text(s2)
print(n, len(sys.argv) - 1)
