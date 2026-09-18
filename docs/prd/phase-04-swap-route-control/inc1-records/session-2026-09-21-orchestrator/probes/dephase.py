#!/usr/bin/env python3
"""⚠⚠ SUPERSEDED BY `entangle.py`.  DO NOT CITE THIS FILE AS CLEARANCE.

Kept, not deleted, because WHAT IT MISSED is the record worth having.

This instrument builds its ancestry graph ONLY from the handle operands of a
`cq_template_*` mint.  Every correlation created by a PERMUTATION gate --
`cqrt_cnot`, `cqrt_toffoli`, `cqrt_cswap`, `cqrt_copy_<W>`,
`cqrt_copy_<W>_controlled`, `cqrt_x_controlled` -- therefore produces NO EDGE.
Those gates are exactly how the 4.4/4.5 value-merge and the rail-root CNOT copy
build their rails, so in `o1_owner_plus_hoisted` the merged rails and the flag
ancillas all have EMPTY ANCESTRY under it.

MEASURED by the independent Rule-13 round 5 (F-2, 2026-09-21): it reports "OK" on
all three canonical Rule-8 violations (a CNOT record, a controlled-copy record and
a Toffoli record held live across an Ry on the register they record) AND on a real
compiled program, `y3_rot_merged_unrolled.c`, about which THE COMPILER ITSELF
EMITS `cq rotation lowering: non-diagonal gate over a live derived record`.

⚠ IT HAD ALREADY LIED ONCE BEFORE THAT, IN THE SAME DIRECTION, AND WAS FIXED:
its first spelling scored a real mutant CLEAN because a guard written to permit
deliberate Rule-6 leaks (`unc != 0`) also permitted "freed but never uncomputed",
i.e. the Rule-6 dirty free itself.  Two independent misses, both in the MISSED
direction, on one instrument, in one day.  `CLAUDE.md` L10: an instrument's
failure mode is to report a pass, so the only instrument worth citing is one that
has been made to fail on purpose -- and nine boundary controls were not enough
here, because every one of them was written by the person who wanted the answer.

USE `entangle.py` (same directory): edge-complete over the permutation gates,
XOR/symmetric-difference for linear gates so an exactly-paired CNOT bracket
cancels, UNION for non-linear ones, measurement modelled as a projection, an
adjoint-operand-identity axis, an UNCLASSIFIED-symbol refusal so a new `cqrt_*`
cannot be silently guessed, and 18 boundary controls including two null controls.

What this file still does correctly, and why it is left runnable: the per-rail
mint/_unc/free LEDGER (multiplicity, double-free, use-after-free, dirty free
including the template-rail case stage 2b is structurally blind to).  Those
answers were checked against `entangle.py` and agree.  It is the ENTANGLEMENT
axis alone that is unsound here.
"""
import re, sys

MINT  = re.compile(r'^(?P<sym>cq_template_\w+?|cqrt_alloc_\w+)\((?P<args>[^)]*)\) -> (?P<out>h\d+)$')
UNC   = re.compile(r'^(?P<sym>cq_template_\w+_unc)\((?P<args>[^)]*)\)$')
FREE  = re.compile(r'^cqrt_free\((?P<h>h\d+)\)$')
RY    = re.compile(r'^cqrt_ry_\w+\((?P<h>h\d+),')
RYC   = re.compile(r'^cqrt_ry_\w+_controlled\((?P<c>h\d+), (?P<h>h\d+),')
MEAS  = re.compile(r'^cqrt_measure_\w+\((?P<h>h\d+)\)')
CNOT  = re.compile(r'^cqrt_cnot\((?P<s>h\d+), (?P<t>h\d+)\)$')

def handles(s):
    return re.findall(r'\bh\d+\b', s)

def analyse(path):
    lines = [l.strip() for l in open(path) if l.strip()]
    parent = {}          # rail -> [operand rails at mint]
    mint, unc, free, cnot, rysum = {}, {}, {}, {}, {}
    alloc = set()
    alive = set()
    findings = []

    def ancestors(h, seen=None):
        seen = seen if seen is not None else set()
        for p in parent.get(h, []):
            if p not in seen:
                seen.add(p); ancestors(p, seen)
        return seen

    for i, l in enumerate(lines, 1):
        m = MINT.match(l)
        if m and not m.group('sym').endswith('_unc'):
            out = m.group('out')
            src = [h for h in handles(m.group('args'))]
            # a re-mint of a name already alive is a fresh rail: reset its lineage
            parent[out] = src
            if m.group('sym').startswith('cqrt_alloc'):
                alloc.add(out)
            mint[out] = mint.get(out, 0) + 1
            alive.add(out)
            continue
        m = UNC.match(l)
        if m:
            hs = handles(m.group('args'))
            if hs:
                unc[hs[0]] = unc.get(hs[0], 0) + 1
            continue
        m = CNOT.match(l)
        if m:
            cnot[m.group('t')] = cnot.get(m.group('t'), 0) + 1
            continue
        m = FREE.match(l)
        if m:
            h = m.group('h'); free[h] = free.get(h, 0) + 1
            # Rule 6: a free is a hardware reset.  A TEMPLATE-minted rail is
            # provably |0> only if its forward gate was adjointed, or if it is an
            # ancilla returned by a paired CNOT (x (+) x = 0).  ** THIS IS THE
            # CHECK STAGE 2b IS STRUCTURALLY BLIND TO ** -- it has no cqrt_alloc
            # to count for a template rail (CLAUDE.md, stage-2b note).
            if h in parent and h not in alloc \
               and unc.get(h, 0) < mint.get(h, 0) and cnot.get(h, 0) % 2 != 0 \
               and abs(rysum.get(h, 0.0)) > 1e-12:
                findings.append(
                    f"L{i}: free of {h} minted x{mint.get(h,0)} but _unc x{unc.get(h,0)} "
                    f"and no paired CNOT return — DIRTY FREE (Rule 6)")
            if h not in alive:
                findings.append(f"L{i}: free of {h} which is not alive (double-free / UAF)")
            alive.discard(h)
            continue
        m = RYC.match(l) or RY.match(l)
        if m:
            tgt = m.group('h')
            if not RYC.match(l):
                ang = l.split(',')[-1].rstrip(')').strip()
                try:
                    rysum[tgt] = rysum.get(tgt, 0.0) + float.fromhex(ang)
                except ValueError:
                    rysum[tgt] = rysum.get(tgt, 0.0) + float(ang)
            bad = sorted(r for r in alive if r != tgt and tgt in ancestors(r))
            if bad:
                findings.append(f"L{i}: {l.split('(')[0]} on {tgt} with LIVE records of it: {bad}")
            continue
        m = MEAS.match(l)
        if m:
            tgt = m.group('h')
            bad = sorted(r for r in alive if r != tgt and tgt in ancestors(r))
            if bad:
                findings.append(f"L{i}: measure of {tgt} with LIVE records of it: {bad}")
            continue

    for h in sorted(mint, key=lambda x: int(x[1:])):
        # A rail LEFT ALLOCATED with 0 uncs is the Rule-6 accepted leak and is
        # reported, not flagged, by the caller.  Any OTHER mint/_unc disagreement
        # is the multiplicity hazard `railLocalQualifies` names.
        # An ancilla discharged by a PAIRED CNOT (x (+) x = 0) has no _unc by
        # construction and is not a multiplicity disagreement.
        cnot_returned = unc.get(h, 0) == 0 and cnot.get(h, 0) > 0 and cnot.get(h, 0) % 2 == 0
        # Ry ADDITIVITY discharge: ry(+t) ... ry(-t) returns an alloc-minted prep
        # rail to |0> exactly, with no `_unc` symbol.  The FLAT form uses it where
        # the ROLLED form leaves the rail allocated (Rule 6) -- both correct.
        ry_returned = (unc.get(h, 0) == 0 and h in alloc
                       and abs(rysum.get(h, 0.0)) < 1e-12)
        if mint[h] != unc.get(h, 0) and not (unc.get(h, 0) == 0 and h in alive) \
           and not cnot_returned and not ry_returned:
            findings.append(f"{h}: mint x{mint[h]} but _unc x{unc.get(h,0)} — MULTIPLICITY")
        if free.get(h, 0) > 1:
            findings.append(f"{h}: freed x{free[h]}")
    leaked = sorted(alive, key=lambda x: int(x[1:]))
    return findings, leaked, mint, unc, free

def selftest():
    import tempfile, os
    ok = True
    # control 1: a NULL trace (no gates) must produce no finding
    cases = [
        ("null", "cqrt_alloc_i32(4) -> h0\ncqrt_measure_i32(h0) -> 0\n", 0),
        # control 2: a LEAK -- an and-rail of h0 alive across a Ry on h0
        ("leak", "cqrt_alloc_i32(4) -> h0\ncqrt_ry_i32(h0, 1.0)\n"
                 "cq_template_and_i32_hl(h0, 1) -> h1\ncqrt_ry_i32(h0, 0.9)\n"
                 "cqrt_measure_i32(h0) -> 0\n", 2),
        # control 3: the same, DISCHARGED -- must be clean
        ("clean", "cqrt_alloc_i32(4) -> h0\ncqrt_ry_i32(h0, 1.0)\n"
                  "cq_template_and_i32_hl(h0, 1) -> h1\n"
                  "cq_template_and_i32_hl_unc(h1, h0, 1)\ncqrt_free(h1)\n"
                  "cqrt_ry_i32(h0, 0.9)\ncqrt_measure_i32(h0) -> 0\n", 0),
        # control 4: multiplicity -- one mint, two _uncs
        ("mult", "cqrt_alloc_i32(4) -> h0\ncq_template_and_i32_hl(h0, 1) -> h1\n"
                 "cq_template_and_i32_hl_unc(h1, h0, 1)\n"
                 "cq_template_and_i32_hl_unc(h1, h0, 1)\ncqrt_free(h1)\n", 1),
        # control 6: a template rail FREED WITHOUT ITS _unc -- the gap stage 2b
        # is blind to, and the mutation (M3) that this checker MISSED on its
        # first spelling.  It must now be caught.
        ("dirtyfree", "cqrt_alloc_i32(4) -> h0\ncq_template_and_i32_hl(h0,1) -> h1\n"
                      "cqrt_free(h1)\n", 1),
        # control 7: an ancilla returned by a PAIRED CNOT is a proven-|0> free
        ("cnotret", "cqrt_alloc_i32(4) -> h0\ncqrt_alloc_i1(0) -> h1\n"
                    "cqrt_cnot(h0, h1)\ncqrt_cnot(h0, h1)\ncqrt_free(h1)\n", 0),
        # control 8: Ry-additivity discharge of a prep rail -- must be CLEAN.
        ("ryret", "cqrt_alloc_i1(0) -> h0\ncqrt_ry_i1(h0, 0x1p-1)\n"
                  "cqrt_ry_i1(h0, -0x1p-1)\ncqrt_free(h0)\n", 0),
        # control 9: the SAME WITHOUT the adjoint -- a dirty free of a rotated
        # rail, Ry(t)|0> != |0>.  MUST be caught.
        ("rydirty", "cqrt_alloc_i1(0) -> h0\ncqrt_ry_i1(h0, 0x1p-1)\n"
                    "cqrt_free(h0)\n", 1),
        # control 5: double free
        ("dfree", "cqrt_alloc_i32(4) -> h0\ncq_template_and_i32_hl(h0,1) -> h1\n"
                  "cq_template_and_i32_hl_unc(h1, h0, 1)\ncqrt_free(h1)\ncqrt_free(h1)\n", 2),
    ]
    for name, body, want in cases:
        p = tempfile.mktemp(suffix=".trace"); open(p, "w").write(body)
        f, _, _, _, _ = analyse(p); os.unlink(p)
        got = len(f)
        tag = "ok " if got == want else "FAIL"
        if got != want: ok = False
        print(f"  [{tag}] selftest {name}: expected {want} finding(s), got {got}  {f if got!=want else ''}")
    return ok

if __name__ == "__main__":
    if "--selftest" in sys.argv:
        print("BOUNDARY CONTROLS (a checker nobody has tried to fool is one nobody should trust):")
        sys.exit(0 if selftest() else 1)
    bad = 0
    for p in sys.argv[1:]:
        f, leaked, mint, unc, free = analyse(p)
        name = p.split('/')[-1].replace('.trace', '')
        nm = sum(mint.values()); nu = sum(unc.values()); nf = sum(free.values())
        print(f"{name:34s} mints={nm:3d} uncs={nu:3d} frees={nf:3d} left-allocated={leaked}")
        for x in f:
            print(f"    !! {x}"); bad += 1
        if not f:
            print(f"    OK: no multiplicity, no double-free, no live record across any Ry or measure")
    sys.exit(1 if bad else 0)
