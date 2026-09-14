#!/usr/bin/env python3
"""Static scan for the RULED SHAPE: a `@cq_theta_*` call inside a CFG cycle whose
arg-0 is defined OUTSIDE that cycle (loop-invariant re-read).  Text-level parse of
each .ll; CFG from terminators; cycles by SCC.  Deliberately CRUDE and over-broad —
every hit is then MEASURED, so false positives cost a run, not a conclusion."""
import re, sys, os, glob
from collections import defaultdict

def parse_fn_blocks(text):
    fns = []
    for m in re.finditer(r'^define[^\n]*?@([\w.$]+)\([^\n]*\{\n(.*?)^\}', text, re.S | re.M):
        fns.append((m.group(1), m.group(2)))
    return fns

def blocks_of(body):
    blocks, cur, name = [], [], "%0"
    lines = body.split('\n')
    # implicit entry label
    for ln in lines:
        lm = re.match(r'^([\w.$-]+):', ln)
        if lm:
            blocks.append((name, cur)); name = '%' + lm.group(1); cur = []
        else:
            cur.append(ln)
    blocks.append((name, cur))
    return blocks

def main():
    hits = []
    for f in sorted(glob.glob(sys.argv[1])):
        text = open(f, errors='replace').read()
        if 'cq_theta_' not in text:
            continue
        for fname, body in parse_fn_blocks(text):
            bl = blocks_of(body)
            names = [b[0] for b in bl]
            idx = {n: i for i, n in enumerate(names)}
            succ = defaultdict(list)
            defblk = {}
            thetas = []           # (blockname, resultname, arg0)
            for bn, lines in bl:
                for ln in lines:
                    dm = re.match(r'\s*(%[\w.$-]+)\s*=', ln)
                    if dm: defblk[dm.group(1)] = bn
                    tm = re.search(r'(%[\w.$-]+)\s*=.*?@cq_theta_\w+\(\s*\w+[^,]*?\s*(%[\w.$-]+|[-\d]+)', ln)
                    if tm and '@cq_theta_' in ln:
                        thetas.append((bn, tm.group(1), tm.group(2)))
                    for t in re.findall(r'label (%[\w.$-]+)', ln):
                        succ[bn].append(t)
            # phi incomings also define; phi result def block is its own block (handled)
            # Tarjan SCC (iterative)
            index = {}; low = {}; onstk = {}; stk = []; ctr = [0]; sccs = []
            def strong(v):
                work = [(v, 0)]
                while work:
                    node, pi = work[-1]
                    if pi == 0:
                        index[node] = low[node] = ctr[0]; ctr[0] += 1
                        stk.append(node); onstk[node] = True
                    recurse = False
                    for i in range(pi, len(succ[node])):
                        w = succ[node][i]
                        if w not in index:
                            work[-1] = (node, i + 1); work.append((w, 0)); recurse = True; break
                        elif onstk.get(w):
                            low[node] = min(low[node], index[w])
                    if recurse: continue
                    if low[node] == index[node]:
                        comp = []
                        while True:
                            w = stk.pop(); onstk[w] = False; comp.append(w)
                            if w == node: break
                        sccs.append(comp)
                    work.pop()
                    if work:
                        parent = work[-1][0]
                        low[parent] = min(low[parent], low[node])
            for n in names:
                if n not in index: strong(n)
            cyc = {}
            for comp in sccs:
                iscycle = len(comp) > 1 or (comp[0] in succ[comp[0]])
                if iscycle:
                    for n in comp: cyc[n] = id(comp)
            for bn, res, a0 in thetas:
                if bn in cyc and a0.startswith('%'):
                    db = defblk.get(a0)
                    if db is None:            # a phi/arg defined elsewhere
                        continue
                    if cyc.get(db) != cyc[bn]:
                        hits.append((os.path.basename(f), fname, bn, res, a0, db))
    for h in hits:
        print('|'.join(map(str, h)))
    print(f"# {len(hits)} hit(s) in {len(set(h[0] for h in hits))} file(s)", file=sys.stderr)

main()
