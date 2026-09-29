#!/usr/bin/env python3
"""The _ternary slice under the NEW header must hand the pass the SAME function bodies the
pre-fmt3 if/else slice did under the ORIGINAL header (the SimplifyCFG fold's output). Compares
every `define` body with attribute-group references (` #N`) stripped; prints IDENTICAL or a diff."""
import re, subprocess, sys, tempfile, difflib, os
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b"
S = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3"
L = "/usr/local/opt/llvm@19/bin"
def bodies(inc, src):
    t = tempfile.mktemp(suffix=".ll")
    subprocess.run([L + "/clang", "-I" + inc, "-include", "CQ.h", "-O1", "-emit-llvm", "-S", src, "-o", t], check=True)
    txt = open(t).read(); os.remove(t)
    out = []
    for m in re.finditer(r"^define .*?^}", txt, re.M | re.S):
        out.append(re.sub(r" #\d+", "", m.group(0)))
    return "\n".join(out).splitlines()
bad = 0
for base in ("slice_control_angle_select_ry", "slice_control_angle_select_ry_ne",
             "slice_control_angle_select_ry_derived_base"):
    a = bodies(S + "/orig_inc", f"{W}/tests/e2e/{base}.c")
    b = bodies(W + "/include", f"{W}/tests/e2e/{base}_ternary.c")
    if a == b:
        print(f"IDENTICAL  {base} (orig header, if/else) == {base}_ternary (nomerge header)")
    else:
        bad += 1
        print(f"DIFFERS    {base}")
        print("\n".join(difflib.unified_diff(a, b, lineterm="")))
sys.exit(1 if bad else 0)
