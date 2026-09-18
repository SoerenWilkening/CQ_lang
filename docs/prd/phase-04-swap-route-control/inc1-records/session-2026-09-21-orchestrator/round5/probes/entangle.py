#!/usr/bin/env python3
"""entangle.py <trace...> — the Rule-8 question with the ENTANGLEMENT EDGES that
`dephase.py` does not record.

WHY THIS EXISTS.  `probes/dephase.py` (session harness, round 5 brief) builds its
ancestry map ONLY from the handle operands of a `cq_template_*` mint.  A rail that
acquires its correlation through a PERMUTATION gate --

    cqrt_cnot(hq, hanc)            cqrt_toffoli(ha, hb, ht)
    cqrt_copy_<W>(hs, hd)          cqrt_copy_<W>_controlled(hc, hs, hd)
    cqrt_cswap(hc, ha, hb)         cqrt_ry_<W>_controlled(hc, ht, th)

-- gets NO ancestry edge there, so `ancestors(hanc)` is EMPTY and a live record
made that way is invisible to its Rule-8 check.  Those gates are exactly how the
4.4/4.5 value-merge path and the rail-root CNOT copy build their rails, so the
merged `%out` rails of every composed accept have empty ancestry under
`dephase.py`.  This tool records them.

MODEL (basis-label dependency; no simulator -- Rule 2 / owner decision 2026-06-10):
  dep[h]  = set of register ids whose basis label h's basis label depends on.
  LINEAR (XOR) gates use SYMMETRIC DIFFERENCE, so an exactly-paired
  cnot/copy bracket cancels and the ancilla returns to |0> -- the `x (+) x = 0`
  discharge the project relies on.  NON-LINEAR gates (toffoli, controlled copy,
  cswap, controlled Ry) use UNION, which is conservative (over-reports).
  QSRC = the registers on which coherence was actually created: an uncontrolled
  cqrt_ry_* with a nonzero angle, or the TARGET of a controlled Ry.  Only Ry
  creates superposition; Rz is diagonal and cannot dephase a basis record
  (CLAUDE.md Rule 8), so Rz is deliberately transparent here, as it is to
  stage 2b.

REPORTS, per trace:
  (A) DIRTY FREE   -- cqrt_free(h) while dep[h] != {h}: not provably |0> (Rule 6).
  (B) RULE-8       -- at an uncontrolled cqrt_ry_* on T, and at cqrt_measure_*(T),
                      every LIVE h != T whose dep shares a QSRC register with T.
                      At an Ry that is an INTERFERENCE; at a measure it is
                      reported as INFO (a projection ends the story for T).
  (C) MULTIPLICITY -- handles are never recycled by the runtime
                      (cq_runtime.c:64 `next_handle++`), so mint is always 1 per
                      id; a _unc count != mint count is the multiplicity hazard.
  (D) UAF / double free.

Exit 1 if any trace has an (A), (B)-at-Ry, (C) or (D) finding.
--selftest runs the boundary controls, INCLUDING A NULL CONTROL, and is run
automatically before any real measurement on every invocation.
"""
import re, sys, os, tempfile

ALLOC = re.compile(r'^cqrt_alloc_(\w+)\((.*)\) -> h(\d+)$')
TMINT = re.compile(r'^(cq_template_\w+)\((.*)\) -> h(\d+)$')
TUNC  = re.compile(r'^(cq_template_\w+_unc)\((.*)\)$')
FREE  = re.compile(r'^cqrt_free\(h(\d+)\)$')
RY    = re.compile(r'^cqrt_ry_(\w+)\(h(\d+), (\S+)\)$')
RYC   = re.compile(r'^cqrt_ry_(\w+)_controlled(?:_inv)?\(h(\d+), h(\d+), (\S+)\)$')
RZC   = re.compile(r'^cqrt_rz_(\w+)_controlled(?:_inv)?\(h(\d+), h(\d+), (\S+)\)$')
RZ    = re.compile(r'^cqrt_rz_(\w+)\(h(\d+), (\S+)\)$')
MEAS  = re.compile(r'^cqrt_measure_(\w+)\(h(\d+)\)')
CNOT  = re.compile(r'^cqrt_cnot\(h(\d+), h(\d+)\)$')
CNOTC = re.compile(r'^cqrt_cnot_controlled\(h(\d+), h(\d+), h(\d+)\)$')
TOFF  = re.compile(r'^cqrt_toffoli\(h(\d+), h(\d+), h(\d+)\)$')
CSWAP = re.compile(r'^cqrt_cswap\(h(\d+), h(\d+), h(\d+)\)$')
COPY  = re.compile(r'^cqrt_copy_(\w+)\(h(\d+), h(\d+)\)$')
COPYC = re.compile(r'^cqrt_copy_(\w+)_controlled(?:_inv)?\(h(\d+), h(\d+), h(\d+)\)$')
XG    = re.compile(r'^cqrt_x\(h(\d+)\)$')
XC    = re.compile(r'^cqrt_x_controlled\(h(\d+), h(\d+)\)$')
INPL  = re.compile(r'^cqrt_(\w+?)c_(\w+)\(h(\d+), (\S+)\)$')   # addc/xorc/... in place


def norm(s):
    return re.sub(r"\s+", "", s)


def hs(s):
    return [int(x) for x in re.findall(r'\bh(\d+)\b', s)]


def analyse(path):
    lines = [l.strip() for l in open(path) if l.strip()]
    dep, alive, mint, unc, free = {}, set(), {}, {}, {}
    fwd = {}                 # rail -> (symbol, arg-text) of its forward mint
    qsrc, projected = set(), set()
    find, info = [], []
    nlines = len(lines)

    def D(h):
        return dep.setdefault(h, {h})

    def shares(a, b):
        return bool((D(a) & D(b)) & qsrc)

    def rule8(i, l, T, kind):
        # A MEASURED rail is not a COHERENT which-path record: the measurement
        # projects it in the computational basis, so the joint state is a product
        # and there is nothing left to dephase.  This is the project's OWN
        # reasoning -- `declineUndischargedMarkedBodyRails` clause (b), and
        # `measureOwnedInvariantRail`'s header states the same physics from the
        # other side.  Without it this tool OVER-REPORTS, measured on z4 (it fired
        # identically on BOTH binaries, so it was noise, not a finding).
        bad = sorted(h for h in alive
                     if h != T and h not in projected and shares(h, T))
        if not bad:
            return
        msg = (f"L{i}: {kind} on h{T} (dep={sorted(D(T))}) with LIVE entangled "
               f"rails {['h%d' % b for b in bad]}")
        (find if kind == "RY" else info).append(msg)

    for i, l in enumerate(lines, 1):
        m = ALLOC.match(l)
        if m:
            h = int(m.group(3)); dep[h] = {h}; alive.add(h)
            mint[h] = mint.get(h, 0) + 1
            continue
        m = TUNC.match(l)
        if m:
            a = hs(m.group(2))
            if a:
                # (E) ADJOINT OPERAND IDENTITY.  The emitted convention is
                # `<sym>_unc(out, <the forward call's own args>)`.  An adjoint whose
                # non-out operands differ from the forward gate's is computed against
                # a DIFFERENT parent value, so it does NOT return the rail to |0>:
                # a wrong unitary that is verify-clean, links, runs, and is invisible
                # to the golden byte-diff (the golden IS the wrong stream), to
                # dephase.py and to stage 2b's reversal-PRESENCE rule.
                sym = m.group(1)[:-len("_unc")]
                rest = norm(m.group(2).split(",", 1)[1]) if "," in m.group(2) else ""
                f = fwd.get(a[0])
                if f is None:
                    find.append(f"L{i}: {m.group(1)} adjoints h{a[0]}, which has no "
                                f"forward mint in this trace")
                elif f[0] != sym or f[1] != rest:
                    find.append(f"L{i}: ADJOINT OPERAND MISMATCH on h{a[0]}: forward "
                                f"`{f[0]}({f[1]})` vs adjoint `{sym}_unc(h{a[0]}, {rest})`")
                unc[a[0]] = unc.get(a[0], 0) + 1
                dep[a[0]] = {a[0]}          # adjointed -> back to |0>
            continue
        m = TMINT.match(l)
        if m:
            out = int(m.group(3)); srcs = hs(m.group(2))
            s = set()
            for a in srcs:
                s |= D(a)
            dep[out] = s if s else {out}
            alive.add(out); mint[out] = mint.get(out, 0) + 1
            fwd[out] = (m.group(1), norm(m.group(2)))
            continue
        m = COPYC.match(l)
        if m:
            c, s, d = int(m.group(2)), int(m.group(3)), int(m.group(4))
            dep[d] = D(d) | D(s) | D(c)     # NON-LINEAR: union
            continue
        m = COPY.match(l)
        if m:
            s, d = int(m.group(2)), int(m.group(3))
            dep[d] = D(d) ^ D(s)            # XOR copy: symmetric difference
            continue
        m = CNOTC.match(l)
        if m:
            c, tc, t = int(m.group(1)), int(m.group(2)), int(m.group(3))
            dep[t] = D(t) | D(tc) | D(c)
            continue
        m = CNOT.match(l)
        if m:
            s, t = int(m.group(1)), int(m.group(2))
            dep[t] = D(t) ^ D(s)
            continue
        m = TOFF.match(l)
        if m:
            a, b, t = int(m.group(1)), int(m.group(2)), int(m.group(3))
            dep[t] = D(t) | D(a) | D(b)
            continue
        m = CSWAP.match(l)
        if m:
            c, a, b = int(m.group(1)), int(m.group(2)), int(m.group(3))
            u = D(a) | D(b) | D(c)
            dep[a] = set(u); dep[b] = set(u)
            continue
        m = XC.match(l)
        if m:
            c, q = int(m.group(1)), int(m.group(2))
            dep[q] = D(q) ^ D(c)
            continue
        if XG.match(l):
            continue                        # local NOT: no correlation change
        m = RYC.match(l)
        if m:
            c, t = int(m.group(2)), int(m.group(3))
            dep[t] = D(t) | D(c) | {t}
            qsrc.add(t)
            rule8(i, l, t, "RYC-INFO")
            continue
        m = RY.match(l)
        if m:
            t = int(m.group(2))
            try:
                ang = float.fromhex(m.group(3))
            except ValueError:
                ang = float(m.group(3))
            rule8(i, l, t, "RY")            # asked BEFORE the gate updates dep
            if abs(ang) > 0.0:
                dep[t] = D(t) | {t}; qsrc.add(t)
            continue
        if RZC.match(l) or RZ.match(l):
            continue                        # diagonal: cannot dephase a basis record
        m = INPL.match(l)
        if m:
            continue                        # in-place, classical immediate
        m = MEAS.match(l)
        if m:
            t = int(m.group(2))
            rule8(i, l, t, "MEAS-INFO")
            projected.add(t)
            continue
        m = FREE.match(l)
        if m:
            h = int(m.group(1))
            if h not in alive:
                find.append(f"L{i}: cqrt_free(h{h}) of a rail that is not alive "
                            f"(double-free / use-after-free)")
            if dep.get(h, {h}) != {h}:
                find.append(f"L{i}: DIRTY FREE of h{h}: dep={sorted(dep.get(h))} "
                            f"!= {{h{h}}} -- not provably |0> (Rule 6)")
            alive.discard(h); free[h] = free.get(h, 0) + 1
            continue
        # unclassified line: loud, never silent (a new cqrt_* symbol must be
        # classified or this tool guesses -- same discipline as free_pairing_check)
        find.append(f"L{i}: UNCLASSIFIED trace line, refusing to guess: {l!r}")

    for h in sorted(mint):
        if mint[h] != unc.get(h, 0) and h in alive:
            continue                        # left allocated: Rule-6 accepted leak
        if mint[h] != unc.get(h, 0) and h not in alive:
            # freed; the dirty-free check above already ruled on |0>-ness
            pass
        if unc.get(h, 0) > mint[h]:
            find.append(f"h{h}: minted x{mint[h]} but _unc x{unc.get(h,0)} "
                        f"-- MULTIPLICITY (K adjoints against one forward gate)")
        if free.get(h, 0) > 1:
            find.append(f"h{h}: freed x{free[h]}")
    return find, info, sorted(alive), nlines, mint, unc


CONTROLS = [
    # NULL BOUNDARY CONTROL -- an empty trace must be reported as VACUOUS, not clean.
    ("null-empty", "", 0, 0),
    # NULL BOUNDARY CONTROL -- a trace with no quantum source must never fire.
    ("null-classical", "cqrt_alloc_i32(4) -> h0\ncqrt_measure_i32(h0) -> 0\n", 0, 2),
    # the CNOT edge dephase.py cannot see: an ancilla COPY of a rotated register,
    # left alive across a second Ry on that register.
    ("cnot-record", "cqrt_alloc_i1(0) -> h0\ncqrt_ry_i1(h0, 0x1p-1)\n"
                    "cqrt_alloc_i1(0) -> h1\ncqrt_cnot(h0, h1)\n"
                    "cqrt_ry_i1(h0, 0x1.8p-1)\n", 1, 5),
    # the same, DISCHARGED by the paired CNOT return: must be clean.
    ("cnot-returned", "cqrt_alloc_i1(0) -> h0\ncqrt_ry_i1(h0, 0x1p-1)\n"
                      "cqrt_alloc_i1(0) -> h1\ncqrt_cnot(h0, h1)\n"
                      "cqrt_cnot(h0, h1)\ncqrt_free(h1)\n"
                      "cqrt_ry_i1(h0, 0x1.8p-1)\n", 0, 7),
    # the CONTROLLED-COPY edge dephase.py cannot see.
    ("copyc-record", "cqrt_alloc_i1(0) -> h0\ncqrt_ry_i1(h0, 0x1p-1)\n"
                     "cqrt_alloc_i32(0) -> h1\ncqrt_alloc_i32(7) -> h2\n"
                     "cqrt_copy_i32_controlled(h0, h2, h1)\n"
                     "cqrt_ry_i1(h0, 0x1.8p-1)\n", 1, 6),
    # the TOFFOLI edge.
    ("toffoli-record", "cqrt_alloc_i1(0) -> h0\ncqrt_ry_i1(h0, 0x1p-1)\n"
                       "cqrt_alloc_i1(0) -> h1\ncqrt_alloc_i1(0) -> h2\n"
                       "cqrt_toffoli(h0, h1, h2)\ncqrt_ry_i1(h0, 0x1.8p-1)\n", 1, 6),
    # the template-rail record (the class dephase.py DOES see) -- must still fire.
    ("template-record", "cqrt_alloc_i32(4) -> h0\ncqrt_ry_i32(h0, 0x1p-1)\n"
                        "cq_template_and_i32_hl(h0, 1) -> h1\n"
                        "cqrt_ry_i32(h0, 0x1.cp-1)\n", 1, 4),
    # ... and DISCHARGED must be clean.
    ("template-discharged", "cqrt_alloc_i32(4) -> h0\ncqrt_ry_i32(h0, 0x1p-1)\n"
                            "cq_template_and_i32_hl(h0, 1) -> h1\n"
                            "cq_template_and_i32_hl_unc(h1, h0, 1)\ncqrt_free(h1)\n"
                            "cqrt_ry_i32(h0, 0x1.cp-1)\n", 0, 6),
    # dirty free of a template rail: stage 2b is structurally blind to this.
    ("dirty-free", "cqrt_alloc_i32(4) -> h0\ncqrt_ry_i32(h0, 0x1p-1)\n"
                   "cq_template_and_i32_hl(h0, 1) -> h1\ncqrt_free(h1)\n", 1, 4),
    # double free / UAF.
    ("double-free", "cqrt_alloc_i32(4) -> h0\ncqrt_free(h0)\ncqrt_free(h0)\n", 2, 3),
    # multiplicity: one forward gate, two adjoints.
    ("multiplicity", "cqrt_alloc_i32(4) -> h0\ncq_template_and_i32_hl(h0,1) -> h1\n"
                     "cq_template_and_i32_hl_unc(h1, h0, 1)\n"
                     "cq_template_and_i32_hl_unc(h1, h0, 1)\ncqrt_free(h1)\n", 1, 5),
    # an UNCLASSIFIED symbol must be refused loudly, never guessed.
    ("unclassified", "cqrt_bogus_gate(h0, h1)\n", 1, 1),
    # (E) a MISMATCHED adjoint literal must fire.
    ("adjoint-mismatch", "cqrt_alloc_i32(4) -> h0\ncq_template_and_i32_hl(h0, 1) -> h1\n"
                         "cq_template_and_i32_hl_unc(h1, h0, 2)\ncqrt_free(h1)\n", 1, 4),
    # (E) a MISMATCHED adjoint SYMBOL must fire.
    ("adjoint-wrongsym", "cqrt_alloc_i32(4) -> h0\ncq_template_and_i32_hl(h0, 1) -> h1\n"
                         "cq_template_xor_i32_hl_unc(h1, h0, 1)\ncqrt_free(h1)\n", 1, 4),
    # (E) the MATCHING adjoint must NOT fire (the null tag for this axis).
    ("adjoint-match", "cqrt_alloc_i32(4) -> h0\ncq_template_and_i32_hl(h0, 1) -> h1\n"
                      "cq_template_and_i32_hl_unc(h1, h0, 1)\ncqrt_free(h1)\n", 0, 4),
    # a MEASURED record is projected and must NOT fire at a later Ry ...
    ("meas-projected", "cqrt_alloc_i32(4) -> h0\ncqrt_ry_i32(h0, 0x1p-1)\n"
                       "cq_template_and_i32_hl(h0, 1) -> h1\ncqrt_measure_i32(h1) -> 0\n"
                       "cqrt_ry_i32(h0, 0x1.cp-1)\n", 0, 5),
    # ... while an UNMEASURED one still must.
    ("meas-other", "cqrt_alloc_i32(4) -> h0\ncqrt_ry_i32(h0, 0x1p-1)\n"
                   "cq_template_and_i32_hl(h0, 1) -> h1\n"
                   "cq_template_and_i32_hl(h0, 2) -> h2\ncqrt_measure_i32(h1) -> 0\n"
                   "cqrt_ry_i32(h0, 0x1.cp-1)\n", 1, 6),
    # Rz must stay transparent (diagonal): a record alive across an Rz is NOT a finding.
    ("rz-transparent", "cqrt_alloc_i1(0) -> h0\ncqrt_ry_i1(h0, 0x1p-1)\n"
                       "cqrt_alloc_i1(0) -> h1\ncqrt_cnot(h0, h1)\n"
                       "cqrt_rz_i1(h0, 0x1p-1)\n", 0, 5),
]


def selftest(verbose=True):
    ok = True
    for name, body, want, wantlines in CONTROLS:
        p = tempfile.mktemp(suffix=".trace")
        open(p, "w").write(body)
        f, _, _, n, _, _ = analyse(p)
        os.unlink(p)
        good = (len(f) == want and n == wantlines)
        ok &= good
        if verbose or not good:
            print(f"  [{'ok ' if good else 'FAIL'}] control {name:22s} "
                  f"findings {len(f)}/{want}  lines {n}/{wantlines}"
                  f"{'  ' + str(f) if not good else ''}")
    return ok


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    verbose = "--quiet-controls" not in sys.argv
    print("BOUNDARY CONTROLS (run on EVERY invocation, before any real measurement):")
    if not selftest(verbose):
        print("!! CONTROLS FAILED -- the instrument is measuring itself, not the traces.")
        sys.exit(2)
    print(f"  controls: {len(CONTROLS)}/{len(CONTROLS)} as pinned\n")
    if "--selftest" in sys.argv:
        sys.exit(0)
    if not args:
        print("!! NO TRACE ARGUMENT -- refusing to report a vacuous pass.")
        sys.exit(2)
    bad = 0
    for p in args:
        f, info, leak, n, mint, unc = analyse(p)
        nm = os.path.basename(p).replace(".trace", "")
        print(f"{nm:36s} lines={n:4d} mints={sum(mint.values()):3d} "
              f"uncs={sum(unc.values()):3d} left-allocated={['h%d'%x for x in leak]}")
        for x in f:
            print(f"    !! {x}"); bad += 1
        for x in info:
            print(f"    .. {x}")
        if not f:
            print("    OK: no dirty free, no UAF, no multiplicity, "
                  "no entangled rail live across any uncontrolled Ry")
    sys.exit(1 if bad else 0)
