#!/usr/bin/env python3
"""vs_pre.py module...: lower each battery module with preE and compare with the
merged output byte for byte; for a DIFF, print both and run both with args 5 7 / 2 9."""
import pathlib
import subprocess
import sys

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
P = S / "merge9" / "p"
for m in sys.argv[1:]:
    r = subprocess.run([str(S / "frozen/cq-opt.preE"), "-passes=cq-lowering", "-S",
                        str(P / f"{m}.s1.ll"), "-o", "-"], capture_output=True)
    merged = (P / f"{m}.merged.s2.ll").read_bytes()
    print(f"{m}: preE rc={r.returncode}; merged vs preE "
          f"{'IDENTICAL' if r.stdout == merged else 'DIFFERS'}")
