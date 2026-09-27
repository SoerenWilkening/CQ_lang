#!/usr/bin/env python3
"""tdiff.py TAG base...: print the C and T traces (args "5 7" and "2 9") of each
pair built by battery.py, and their diff."""
import difflib
import pathlib
import subprocess
import sys

P = pathlib.Path(__file__).resolve().parent / "p"
tag = sys.argv[1]
for b in sys.argv[2:]:
    for args in ("5 7", "2 9"):
        out = {}
        for v in ("C", "T"):
            exe = P / f"{b}{v}.{tag}.exe"
            if not exe.exists():
                out[v] = ["<no exe>"]
                continue
            r = subprocess.run([str(exe)] + args.split(), capture_output=True, text=True)
            out[v] = r.stdout.splitlines() + [f"exit={r.returncode}"]
        d = list(difflib.unified_diff(out["C"], out["T"], "C", "T", lineterm="", n=1))
        print(f"### {b} args={args}: {'IDENTICAL' if not d else 'DIFF'}")
        for l in d[2:]:
            print("   ", l)
