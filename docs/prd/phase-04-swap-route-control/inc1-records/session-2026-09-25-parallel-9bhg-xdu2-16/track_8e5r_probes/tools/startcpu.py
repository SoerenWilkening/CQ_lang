#!/usr/bin/env python3
"""startcpu.py N BIN... — child CPU of `BIN -passes=nope` (exits right after
static init + argument parsing), interleaved across binaries, N rounds."""
import os, subprocess, sys
n = int(sys.argv[1]); bins = sys.argv[2:]
tot = {b: 0.0 for b in bins}
for _ in range(n):
    for b in bins:
        p = subprocess.Popen([b, "-passes=nope"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        _, _, ru = os.wait4(p.pid, 0)
        tot[b] += ru.ru_utime + ru.ru_stime
for b in bins:
    print(f"{os.path.basename(b)}: {tot[b]/n*1000:.1f} ms CPU per launch (n={n})")
