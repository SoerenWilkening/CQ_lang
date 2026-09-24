#!/usr/bin/env python3
"""Scratch: run r6/*.ll (prebuilt linked modules) + r6/{spc,sye}.c on this build,
the 60ac0fcb subject (cq-opt.r5) and the aad63450 oracle."""
import pathlib
import re
import subprocess
H = pathlib.Path(__file__).resolve().parent
W = H.parent
S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "7c7a42b7-0d81-41a3-a96f-61401a5ee1b7/scratchpad")
BINS = [("new", W / "build/ir-pass/cq-opt"), ("r5", S / "subject/cq-opt.r5"),
        ("ora", S / "frozen/cq-opt.preE")]
L = "/usr/local/opt/llvm@19/bin/clang"
mods = sorted((H / "r6").glob("x?m.ll"))
for c in ["spc", "sye"]:
    out = H / "r6" / f"{c}.s1.ll"
    subprocess.run([L, f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
                    str(H / "r6" / f"{c}.c"), "-o", str(out)], check=True)
    mods.append(out)
for m in mods:
    row = []
    for tag, b in BINS:
        r = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(m), "-o", "/dev/null"],
                           capture_output=True, text=True)
        e = re.search(r"error: .*?: (cq [^\n]*)", r.stderr)
        row.append(f"{tag}={r.returncode} {e.group(1)[:60] if e else ''}")
    print(m.stem.ljust(8), " | ".join(row))
