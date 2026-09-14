#!/usr/bin/env python3
"""Is the F-D2-1 shape PINNED anywhere in `ir-pass/test`?  (bd 3d8q, Rule-13 round 2.)

THE SHAPE, exactly: a PHI that carries a `@cq_theta_*` result `%t` ACROSS A BACK
EDGE (the incoming block for `%t` is reachable FROM the phi's own block, i.e. the
edge closes a cycle), where `%t` ALSO feeds a dtzb in-place op (`add`/`xor`) — so
the loop-carried name is the PRE-mutation one.  That is `oa1_phitracks_inplace_add.c`
and `oa2_phitracks_inplace_xor.c`; its twin `oa1t_alias_twin.c` carries the POST-add
name and is the same circuit.

Text-level and deliberately CRUDE, like the round-2 review's `scan_r5.py`: CFG from
terminator labels, reachability by BFS, no taint, no `-O1` model, no `select`/`phi`
routing.  A ZERO is EVIDENCE that neither disposition of the pair is pinned — a
LOWER BOUND on the population, never a census (Rule 11).
"""
import re, sys, glob
from collections import defaultdict

def fns(text):
    return re.finditer(r'^define[^\n]*?@([\w.$]+)\([^\n]*\{\n(.*?)^\}', text, re.S | re.M)

def blocks_of(body):
    out, cur, name = [], [], "%0"
    for ln in body.split('\n'):
        lm = re.match(r'^([\w.$-]+):', ln)
        if lm:
            out.append((name, cur)); name = '%' + lm.group(1); cur = []
        else:
            cur.append(ln)
    out.append((name, cur))
    return out

def main():
    pat = sys.argv[1] if len(sys.argv) > 1 else "ir-pass/test/*.ll"
    scanned, hits = 0, []
    for f in sorted(glob.glob(pat)):
        text = open(f, errors='replace').read()
        if 'cq_theta_' not in text:
            continue
        scanned += 1
        for m in fns(text):
            fname, body = m.group(1), m.group(2)
            bl = blocks_of(body)
            succ = defaultdict(list)
            thetas, phis, dtzb_ops = set(), [], []
            for bn, lines in bl:
                for ln in lines:
                    if '@cq_theta_' in ln:
                        m = re.match(r'\s*(%[\w.$-]+)\s*=', ln)
                        if m: thetas.add(m.group(1))
                    if re.match(r'\s*%[\w.$-]+\s*=\s*phi\s', ln):
                        phis.append((bn, re.findall(r'\[\s*(%[\w.$-]+)\s*,\s*(%[\w.$-]+)\s*\]', ln)))
                    m = re.match(r'\s*(%[\w.$-]+)\s*=\s*(?:add|xor)\b(.*)$', ln)
                    if m: dtzb_ops.append((bn, m.group(2)))
                    for t in re.findall(r'label (%[\w.$-]+)', ln):
                        succ[bn].append(t)
            def reaches(a, b):
                seen, work = set(), list(succ[a])
                while work:
                    n = work.pop()
                    if n == b: return True
                    if n in seen: continue
                    seen.add(n); work.extend(succ[n])
                return False
            for phiblk, incs in phis:
                # the dtzb op must itself be INSIDE the cycle the phi closes,
                # else it runs after the loop and can never stale the carry
                # (`control_swap_inloop_postloop_railop*.ll` are exactly that,
                # and were this scan's first three false positives).
                mutated = set(v for blk, ops in dtzb_ops
                              if reaches(phiblk, blk) and reaches(blk, phiblk)
                              for v in re.findall(r'(%[\w.$-]+)', ops) if v in thetas)
                for val, inblk in incs:
                    if val in thetas and val in mutated and (inblk == phiblk or reaches(phiblk, inblk)):
                        hits.append((f.split('/')[-1], fname, val, phiblk, inblk))
    print(f"scanned {scanned} fixtures containing cq_theta_; {len(hits)} hold the F-D2-1 shape")
    for h in hits:
        print("  %s @%s: %s carried into %s from %s (back edge) and dtzb-mutated" % h)

main()
