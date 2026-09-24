#!/usr/bin/env python3
"""Scratch: compile r3/*.c (+ named extras) at -O1, lower with this build and the
aad63450 oracle, print verdicts and the first error line."""
import pathlib
import re
import subprocess
import sys
import time
H = pathlib.Path(__file__).resolve().parent
W = H.parent
L = "/usr/local/opt/llvm@19/bin/clang"
NEW = W / "build/ir-pass/cq-opt"
ORA = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                   "7c7a42b7-0d81-41a3-a96f-61401a5ee1b7/scratchpad/frozen/cq-opt.preE")
srcs = sorted((H / (sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].endswith(".c") else "r3")).glob("*.c")) 
for c in srcs:
    s1 = c.with_suffix(".s1.ll")
    subprocess.run([L, f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
                    str(c), "-o", str(s1)], check=True)
    out = []
    for tag, b in (("new", NEW), ("ora", ORA)):
        t = time.time()
        r = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(s1), "-o",
                            str(c.with_suffix(f".{tag}.ll"))], capture_output=True, text=True)
        m = re.search(r"(cq [^\n]*)", r.stderr)
        out.append(f"{tag}={r.returncode}({time.time()-t:.2f}s) {m.group(1) if m else ''}")
    print(c.stem.ljust(26), " | ".join(out))
