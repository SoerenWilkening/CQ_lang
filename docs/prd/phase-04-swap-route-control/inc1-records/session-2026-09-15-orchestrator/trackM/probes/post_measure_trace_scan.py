#!/usr/bin/env python3
"""post_measure_trace_scan.py — UPPER BOUND on the goldens whose STREAM E3 can move.

Reports, per committed tests/e2e/*.expected.log, every rail handle that appears as an
ARGUMENT of a trace line AFTER a `cqrt_measure_<W>(h)` on that same handle.

WHAT IT IS AND IS NOT (Rule 19 / IMPL_D.md §14.6's own lesson — its first spelling of
this scanner was VACUOUS and was caught by self-test, not by re-reading):
  * It is an UPPER BOUND.  The trace sees RAIL HANDLES; E3's relabel is on SSA NAMES.
    A post-measure op on the same handle whose SSA operand is a DERIVED in-place name
    (not the measured name) is counted here and is NOT relabelled by E3.
  * Excluded, deliberately: a later `cqrt_measure_<W>` on the same handle (idempotent —
    and E3 turns it into a classical passthrough, which is a stream SHORTENING, still
    counted as a mover), and `cqrt_free` (a lifetime op, not a re-use).
  * SELF-TEST (`--selftest`) runs it over synthetic traces with known positives and
    known negatives and FAILS LOUDLY on a miscount, so a `0 of N` can never be read
    as "clean" when it is really "the regex never matched".
"""
import re, sys, glob, os

ARGS = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\(([^)]*)\)')
MEAS = re.compile(r'^\s*cqrt_measure_[a-z0-9]+\((h\d+)\)')
HND  = re.compile(r'\bh\d+\b')

def scan_lines(lines):
    """-> list of (handle, symbol, lineno) for post-measure re-uses."""
    measured = {}        # handle -> first measure line no
    hits = []
    for i, L in enumerate(lines):
        m = MEAS.match(L)
        if m:
            measured.setdefault(m.group(1), i)
            continue
        a = ARGS.match(L)
        if not a:
            continue
        sym, argstr = a.group(1), a.group(2)
        if sym == 'cqrt_free':
            continue
        for h in HND.findall(argstr):
            if h in measured and measured[h] < i:
                hits.append((h, sym, i + 1))
    return hits

def selftest():
    pos = ["cqrt_alloc_i32(0) -> h0",
           "cqrt_ry_i32(h0, 0x1p-1)",
           "cqrt_measure_i32(h0) -> 0",
           "cq_template_icmp_ne_i32_hl(h0, 1) -> h2"]          # 1 hit
    neg1 = ["cqrt_measure_i32(h0) -> 0", "cqrt_measure_i32(h0) -> 0"]   # 0 (re-measure)
    neg2 = ["cqrt_measure_i32(h0) -> 0", "cqrt_free(h0)"]              # 0 (free)
    neg3 = ["cq_template_icmp_ne_i32_hl(h0, 1) -> h2",
            "cqrt_measure_i32(h0) -> 0"]                               # 0 (op BEFORE)
    neg4 = ["cqrt_alloc_i32(0) -> h0", "cqrt_measure_i32(h1) -> 0",
            "cqrt_ry_i32(h0, 0x1p-1)"]                                 # 0 (other handle)
    pos2 = ["cqrt_measure_i32(h0) -> 0",
            "cqrt_ry_i32_controlled(h0, h1, 0x1p-1)"]                  # 1 (h0 as control)
    cases = [(pos,1),(neg1,0),(neg2,0),(neg3,0),(neg4,0),(pos2,1)]
    bad = 0
    for k,(c,want) in enumerate(cases):
        got = len(scan_lines(c))
        ok = "ok" if got == want else "FAIL"
        if got != want: bad += 1
        print(f"  selftest[{k}] want={want} got={got} {ok}")
    if bad:
        print(f"SELFTEST FAILED ({bad} case(s))"); sys.exit(2)
    print("SELFTEST PASSED (6 cases, 2 known positives, 4 known negatives)")

if __name__ == '__main__':
    if '--selftest' in sys.argv:
        selftest(); sys.exit(0)
    root = sys.argv[1] if len(sys.argv) > 1 else 'tests/e2e'
    files = sorted(glob.glob(os.path.join(root, '*.expected.log')))
    n_hit = 0
    for f in files:
        hits = scan_lines(open(f).read().splitlines())
        if hits:
            n_hit += 1
            hs = sorted(set(h for h,_,_ in hits))
            print(f"{os.path.basename(f)} | {len(hs)} handle(s), {len(hits)} post-measure op(s) | "
                  + ", ".join(f"{h}->{s}" for h,s,_ in hits))
    print(f"--- {n_hit} of {len(files)} committed goldens hold a post-measure handle re-use ---")
