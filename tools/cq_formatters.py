#!/usr/bin/env python3
"""LIBC_COVERAGE recipe / CR rule 16: the string formatters (sprintf, snprintf, sscanf and their v forms) are built over
bundle-internal formatting cores __cq_vfprintf / __cq_vfscanf, copies of musl's vfprintf / vfscanf, so no stream call
by name remains in a lifted body. usage: cq_formatters.py in.ll out.ll"""
import re, sys
FORMATTERS = {"sprintf", "snprintf", "sscanf", "vsprintf", "vsnprintf", "vsscanf"}
CORES = {"vfprintf": "__cq_vfprintf", "vfscanf": "__cq_vfscanf"}
text = open(sys.argv[1]).read()
lines = text.split("\n")
out, cur, used = [], None, set()
for l in lines:
    m = re.match(r"define [^@]*@([\w.$]+)\(", l)
    if m:
        cur = m.group(1)
    if cur in FORMATTERS:
        for a, b in CORES.items():
            if f"@{a}(" in l and not l.startswith("define"):
                l = l.replace(f"@{a}(", f"@{b}(")
                used.add(a)
    if l == "}":
        cur = None
    out.append(l)
text = "\n".join(out)
for a in sorted(used):
    m = re.search(rf"(?ms)^define [^\n]*@{a}\(.*?^}}\n", text)
    if not m:
        sys.exit(f"{a}: no body to copy")
    body = m.group(0).replace(f"@{a}(", f"@{CORES[a]}(", 1)
    body = re.sub(r"^define (?:(?:internal|dso_local|local_unnamed_addr|unnamed_addr) )*", "define internal ", body)
    text += "\n" + body
open(sys.argv[2], "w").write(text)
print("renamed in formatters:", sorted(used))
