#!/usr/bin/env python3
"""costab.py — review r1B_8e5r paired, interleaved CPU-cost A/B of two cq-opt
binaries. For R rounds: shuffle the module list; for each module run A and B
back-to-back in a random order; record child user+sys CPU (wait4 rusage). Per
round, ratio = sum(B)/sum(A). Reports mean ratio, stdev across rounds, a 95%
t-interval, and the per-module paired median ratio. A NULL control (A vs A)
runs FIRST and must bracket 1.0, else the instrument measures load, not code.
usage: costab.py --a L=bin --b L=bin --rounds R --mods listfile [--null]"""
import argparse, os, random, statistics as st, subprocess, sys, time
def cpu(binp, mod):
    p = subprocess.Popen([binp, "-passes=cq-lowering", "-S", mod, "-o", "/dev/null"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    _, status, ru = os.wait4(p.pid, 0)
    return ru.ru_utime + ru.ru_stime
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--a", required=True); ap.add_argument("--b", required=True)
    ap.add_argument("--rounds", type=int, default=10); ap.add_argument("--mods", required=True)
    a = ap.parse_args()
    LA, A = a.a.split("=", 1); LB, B = a.b.split("=", 1)
    mods = [l.strip() for l in open(a.mods) if l.strip()]
    rng = random.Random(8)
    ratios = []; per = {m: [] for m in mods}; tA = tB = 0.0
    load0 = os.getloadavg()[0]
    for r in range(a.rounds):
        rng.shuffle(mods); sa = sb = 0.0
        for m in mods:
            if rng.random() < 0.5:
                x = cpu(A, m); y = cpu(B, m)
            else:
                y = cpu(B, m); x = cpu(A, m)
            sa += x; sb += y; per[m].append(y / x if x > 0 else 1.0)
        ratios.append(sb / sa); tA += sa; tB += sb
        print(f"round {r+1}: {LA} {sa:.2f}s  {LB} {sb:.2f}s  ratio {sb/sa:.4f}  load {os.getloadavg()[0]:.0f}", flush=True)
    m = st.mean(ratios); sd = st.stdev(ratios) if len(ratios) > 1 else 0.0
    t = {2:12.71,3:4.30,4:3.18,5:2.78,6:2.57,7:2.45,8:2.36,9:2.31,10:2.26,11:2.23,12:2.20,15:2.14,20:2.09}.get(len(ratios), 2.0)
    hw = t * sd / (len(ratios) ** 0.5)
    med = st.median([st.median(v) for v in per.values()])
    print(f"SUMMARY {LB}/{LA}: modules={len(mods)} rounds={len(ratios)} mean_ratio={m:.4f} "
          f"sd={sd:.4f} 95%CI=[{m-hw:.4f},{m+hw:.4f}] per-module-median={med:.4f} "
          f"totalCPU {LA}={tA:.1f}s {LB}={tB:.1f}s load_start={load0:.0f} load_end={os.getloadavg()[0]:.0f}")
main()
