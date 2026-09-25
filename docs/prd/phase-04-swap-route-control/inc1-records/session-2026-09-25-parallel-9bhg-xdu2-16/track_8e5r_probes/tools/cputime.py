#!/usr/bin/env python3
"""cputime.py LIST STRIDE BIN_A BIN_B [ROUNDS] — per-invocation CHILD CPU time
(user+sys, from wait4 rusage) of running each module through A and B,
interleaved A,B,A,B per module so load drift hits both equally. Serial on
purpose. Prints totals and the ratio, with the denominator."""
import os, subprocess, sys, time

def cpu(b, f):
    p = subprocess.Popen([b, "-passes=cq-lowering", "-S", f, "-o", "/dev/null"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    _, _, ru = os.wait4(p.pid, 0)
    return ru.ru_utime + ru.ru_stime

lst, stride, a, b = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
rounds = int(sys.argv[5]) if len(sys.argv) > 5 else 2
files = [l.strip() for l in open(lst) if l.strip()][::stride]
ta = tb = 0.0
worst = []
for f in files:
    xa = xb = 0.0
    for _ in range(rounds):
        xa += cpu(a, f)
        xb += cpu(b, f)
    ta += xa; tb += xb
    worst.append((xb - xa, os.path.basename(f), xa / rounds, xb / rounds))
print(f"denominator: {len(files)} modules x {rounds} rounds (stride {stride})")
print(f"A {os.path.basename(a)}: {ta/rounds:.2f}s CPU   B {os.path.basename(b)}: {tb/rounds:.2f}s CPU   B/A = {tb/ta:.3f}")
worst.sort(reverse=True)
for d, n, xa, xb in worst[:8]:
    print(f"  {n}: A {xa*1000:.0f}ms  B {xb*1000:.0f}ms")
