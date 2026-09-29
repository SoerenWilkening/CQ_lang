#!/usr/bin/env python3
"""unroll_cmake.py — replace round 2's `foreach(_mt …)` block in tests/e2e/CMakeLists.txt by its
nine literal add_test entries. Why: regex-based harness parsers (this track's own ab.py corpus
builder among them — measured: it registered `e2e-slice-spec-musttail-${_mtn}` as a BUILD-FAIL and
swept none of the three) cannot see entries a CMake loop generates. Same ctest names, same
commands."""
import pathlib
import re

p = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
                 "agent-a333a1777db2f2295/tests/e2e/CMakeLists.txt")
s = p.read_text()
m = re.search(r"foreach\(_mt rhk5_window clone_partial_drop clone_live_arg\)\n"
              r"  string\(REPLACE \"_\" \"-\" _mtn \"\$\{_mt\}\"\)\n(.*?)endforeach\(\)\n", s, re.S)
assert m and s.count("foreach(_mt rhk5_window") == 1
body = m.group(1)
out = []
for mt in ("rhk5_window", "clone_partial_drop", "clone_live_arg"):
    b = body.replace("${_mtn}", mt.replace("_", "-")).replace("${_mt}", mt)
    out.append("\n".join(l[2:] if l.startswith("  ") else l for l in b.splitlines()) + "\n")
s = s[:m.start()] + "".join(out) + s[m.end():]
assert "${_mt" not in s[m.start() - 10:m.start() + 6000]
p.write_text(s)
print("ok")
