#!/usr/bin/env python3
"""golden_multiset_audit.py — the Inc-2a GOLDEN-REGENERATION witness.

bd test_C_libtooling-drbq Inc 2a (the §6a Rz control-in-place peephole),
control-in-place-PRD §9.2 / §12.2(i). Committed as an INSTRUMENT, not as a ctest
gate; read "WHAT IT CANNOT WITNESS" before quoting a green run.

WHY THIS EXISTS. Inc 2a rewrites ~26 committed e2e goldens at once, and PRD §10
names the hazard in one line: "the §9.2 audit is the only thing standing between
'regenerated' and 'regenerated from a broken build'". A golden regenerated from a
compiler that emits the WRONG unitary is perfectly self-consistent — it is a
picture of whatever the compiler did — so the trace byte-diff cannot possibly
catch it. What CAN catch it is a claim about the SHAPE of the change: the only
thing this increment may do to any trace is replace the swap-route quintuple

    cqrt_alloc_<W>(0) -> rail
    cqrt_cswap(f, q, rail)
    cqrt_rz_<W>(rail, theta)          (one or more, all on the same rail)
    cqrt_cswap(f, q, rail)
    cqrt_free(rail)

by one `cqrt_rz_<W>_controlled(f, q, theta)` per rz, with the flag mint, the
`cqrt_x` bracket, the flag strip, the flag free and EVERY OTHER LINE — including
every post-region `_unc` and `cqrt_free` — untouched and in the same order.

FOUR CHECKS PER GOLDEN, ALL ENFORCED (the round-1 review of Inc 2a found (A)
computed-but-never-enforced and no scope check at all — L3 F1/F9):

  (S) SCOPE, asked FIRST and asked of the OLD trace. Inc 2a's scope is the FLAT
      `emitRegion` path; the 4.3 depth-2 nest KEEPS the route. A golden whose OLD
      trace bears a nest signature — a `cqrt_cswap` routing a base that is itself
      a work rail, or two CONTROL flags open at once — must be byte-identical
      old->new, and is reported `OUT-OF-SCOPE` (a failure) if it moved. The
      reducer carries the same fence pointwise: it REFUSES a region whose routed
      base is a work rail, so a collapsed nested inner cannot come out
      `COLLAPSE-ONLY`. Read `out_of_scope_signature`'s docstring for the one case
      this deliberately does NOT catch (the 4.5 switch, which is
      trace-indistinguishable from a sequence of flat regions — measured).

  (A) MULTISET DELTA, the §9.2 form, HANDLE-INVARIANT (`hN` -> `h`, not
      renumber-by-first-appearance: the collapse DELETES a handle-minting line,
      so first-appearance renumbering would bury the arithmetic under noise). The
      observed delta must EQUAL the delta the reducer itself performed — line
      spellings, widths and angles included. It is printed on every audited
      golden, verbose or not, because the numbers PRD §9.2 asks for should be on
      the record whatever the verdict.

  (A2) CSWAP ACCOUNTING. Exactly `2 x n_arms` `cqrt_cswap` lines removed and no
      others moved.

  (B) STRUCTURAL REDUCTION, which is strictly stronger than (A) on ORDER. The OLD
      trace is REDUCED by rewriting every routed REGION into its control-in-place
      form, then both traces are handle-normalised and compared LINE FOR LINE. A
      reordering that leaves the multiset equal (the exact thing bd
      `golden-multiset-diff-audit-2026-08-29` says to look for) still fails here.

`--selftest` runs the audit's own 19-mutant family (L3's, verbatim) plus 4
controls and the out-of-scope probe, against EMBEDDED goldens — no git, no build,
no test tree. Run it after any change to the reducer.

THE `cqrt_x` ARITHMETIC IS PART OF THE EXPECTED SHAPE, NOT AN EXEMPTION. PRD
§9.2 says "the `cqrt_x` brackets … unchanged"; that is true of a NON-negated arm
and FALSE of a negated one, and the difference is structural rather than a
compiler choice. The route brackets EACH of its two `cqrt_cswap`s, so a negated
arm carries FOUR `cqrt_x(f)`; control-in-place brackets the arm's gate run ONCE,
so it carries TWO. The reduction models exactly that (`-2 cqrt_x` per collapsed
negated arm) and the multiset report prints it, so it is visible rather than
waived. Any OTHER `cqrt_x` movement is a failure.

THE ROUTED REGION, as this script matches it (the shape `SwapRouteEmit::emitRegion`
emitted before Inc 2a — allocs batched, route-ins batched, bodies batched,
route-backs batched, frees batched, which is why a per-route contiguous matcher
is NOT enough for an if/else):

    alloc_W(0) -> R_1 ... alloc_W(0) -> R_n          (n = content arms)
    [x(f)] cswap(f,q,R_1) [x(f)] ... [x(f)] cswap(f,q,R_n) [x(f)]
    rz_W(R_1, t) *      ...      rz_W(R_n, t) *
    [x(f)] cswap(f,q,R_1) [x(f)] ... [x(f)] cswap(f,q,R_n) [x(f)]
    free(R_1) ... free(R_n)
  ->
    [x(f)] rz_W_controlled(f,q,t) * [x(f)]   ... per arm, in the same arm order

A region that does NOT match — a 4.3 nested pair, a 4.5 switch, a method-B value
arm, an abort park — is left ALONE by the reducer, which is what lets a golden
that mixes a collapsed flat region with a kept one still pass.

─────────────────────────────────────────────────────────────────────────────────
HOW TO RUN IT (from the repository ROOT)

    python3 tools/golden_multiset_audit.py                # every CHANGED golden
                                                         #   (tracked-modified
                                                         #    AND untracked-new)
    python3 tools/golden_multiset_audit.py --all          # every golden
    python3 tools/golden_multiset_audit.py --selftest     # the mutant validation
    python3 tools/golden_multiset_audit.py tests/e2e/slice_control_phase_diamond.expected.log
    python3 tools/golden_multiset_audit.py --rev HEAD~1   # compare against another rev

Exit code 0 iff every audited golden's diff is exactly the collapse (or empty);
non-zero on any golden that is a `FINDING` or `OUT-OF-SCOPE`. `--verbose` adds the
per-mutant detail in `--selftest` (the (A) delta is printed unconditionally).

─────────────────────────────────────────────────────────────────────────────────
WHAT IT CANNOT WITNESS — read this before quoting a green run

  * IT IS A CLAIM ABOUT THE DIFF, NOT ABOUT THE UNITARY. It proves the new trace
    is the old trace with routes collapsed. If the OLD trace was wrong, the new
    one is wrong in exactly the same way and this script is silent. The old
    stream's correctness is the swap route's own (Phase 4.1, cleared separately).
  * IT CANNOT SEE "FREED AT |0>" — no trace can, at any ABI (bd `8txa`). That is
    stage 2b's job (`tools/free_pairing_check.py`), which runs on the LOWERED IR
    of every slice and must be run as well.
  * A GOLDEN THAT DID NOT CHANGE IS NOT AUDITED by default. `--all` audits every
    golden, but "unchanged" is itself the assertion for those, and `ctest` is what
    checks it. (Since the round-1 review the default set is the union of
    `git diff --name-only` AND `git ls-files --others --exclude-standard`, so a
    brand-new, still-untracked golden is no longer silently skipped — L3 F5.)
  * IT CANNOT DISTINGUISH A 4.5 SWITCH FROM A SEQUENCE OF FLAT REGIONS, so check
    (S) does not cover the switch half of the scope split. That is measured, not
    assumed — see `out_of_scope_signature`. The switch is witnessed by the
    `control_swap_switch_phase*.ll` lit fixtures and by the whole-corpus census
    that no module emits both a `cqrt_cswap` and a `cqrt_rz_*_controlled`.
  * IT READS ONLY THE COMMITTED `.expected.log` FILES. It does not compile
    anything, so it cannot tell you whether the golden matches what the compiler
    emits today — that is the e2e byte-diff.
"""

import argparse
import collections
import os
import re
import subprocess
import sys

CALL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\((.*?)\)(?: -> (.*))?$")
HANDLE = re.compile(r"\bh(\d+)\b")
ALLOC = re.compile(r"cqrt_alloc_(\w+)")
RZ = re.compile(r"cqrt_rz_(\w+)")


def parse(line):
    """-> (callee, [args], ret) or None for a line that is not a trace call."""
    m = CALL.match(line.strip())
    if not m:
        return None
    args = [x.strip() for x in m.group(2).split(",")] if m.group(2) else []
    return m.group(1), args, m.group(3)


def normalise(lines):
    """Renumber handles by FIRST APPEARANCE.

    Mandatory, not cosmetic: the routed trace mints one extra `cqrt_alloc` per
    arm, so every later handle number shifts by a constant that is not a defect.
    A real REORDERING still shows up, because the numbering follows first
    appearance in the (already reduced) sequence.
    """
    m, out = {}, []
    for line in lines:
        def sub(x):
            k = x.group(1)
            if k not in m:
                m[k] = str(len(m))
            return "h" + m[k]
        out.append(HANDLE.sub(sub, line))
    return out


def _route_leg(P, i, rail, flag, base):
    """Match one route leg at `i`: `[x(f)] cswap(f, base, rail) [x(f)]`.

    -> (next_index, negated) or None. The bracket must be the SAME flag on both
    sides; a lone `cqrt_x` is not a bracket and does not match.
    """
    neg = False
    j = i
    if j < len(P) and P[j] and P[j][0] == "cqrt_x" and P[j][1] == [flag]:
        neg = True
        j += 1
    if j >= len(P) or not P[j] or P[j][0] != "cqrt_cswap":
        return None
    if P[j][1] != [flag, base, rail]:
        return None
    j += 1
    if neg:
        if j >= len(P) or not P[j] or P[j][0] != "cqrt_x" or P[j][1] != [flag]:
            return None
        j += 1
    return j, neg


def work_rails(P):
    """Every handle that is routed INTO by some `cqrt_cswap` (its arg 2).

    This is the WORK-RAIL set, and it is deliberately not "every
    `cqrt_alloc_<W>(0)`": a register whose source value happens to be 0 allocates
    the same way (`slice_control_seq_grover`'s `cqrt_alloc_i32(0) -> h0` IS the
    register), so keying on the alloc literal would refuse a legitimate flat
    region. A rail is what a route SWAPS INTO.
    """
    return {p[1][2] for p in P
            if p and p[0] == "cqrt_cswap" and len(p[1]) == 3}


def match_region(P, i, rails_set=None):
    """Try to match a whole ROUTED PHASE REGION starting at trace index `i`.

    Returns (next_index, replacement_lines, n_arms, n_gates, n_negated) or None.
    Everything is matched POSITIONALLY against the pre-2a `emitRegion` emission
    order; any deviation returns None and the caller copies the line through
    unchanged.

    SCOPE FENCE (bd drbq Inc 2a round-1 review, L3 F1): a region whose ROUTED
    BASE is itself a work rail belongs to an ENCLOSING route — that is exactly
    what a 4.3 depth-2 nest's INNER region looks like — and Inc 2a does NOT
    collapse it. Refusing to reduce it here means a golden in which a nested
    inner region HAD collapsed cannot come out `COLLAPSE-ONLY`: the reduced old
    still carries the route and the comparison fails loudly. Measured on the
    unchanged `slice_control_nested_phase` golden: the matcher's one hit there is
    the INNER region (base `h2`, the outer route's rail) and this fence refuses
    it, taking `regions_matched` from 1 to 0.
    """
    # (1) the batched |0> work-rail allocs.
    rails, widths = [], []
    j = i
    while j < len(P) and P[j] and ALLOC.fullmatch(P[j][0] or "") \
            and P[j][1] in (["0"], ["0x0p+0"]) and P[j][2]:
        rails.append(P[j][2])
        widths.append(ALLOC.fullmatch(P[j][0]).group(1))
        j += 1
    if not rails:
        return None

    # (2) the batched route-ins. The flag and the routed base come from the FIRST
    #     cswap and every later leg must agree — a region routes ONE base under
    #     ONE flag (`emitRegion`'s `RestoringRoutes` convention).
    k = j
    if k < len(P) and P[k] and P[k][0] == "cqrt_x":
        k += 1
    if k >= len(P) or not P[k] or P[k][0] != "cqrt_cswap" or len(P[k][1]) != 3:
        return None
    flag, base = P[k][1][0], P[k][1][1]
    if P[k][1][2] != rails[0]:
        return None
    if rails_set is not None and base in rails_set:
        return None  # SCOPE: an inner region of an enclosing route (4.3 nest).
    negated = []
    for r in rails:
        leg = _route_leg(P, j, r, flag, base)
        if leg is None:
            return None
        j, neg = leg
        negated.append(neg)

    # (3) the batched arm bodies: rz on rail 1, then rail 2, … Zero gates on a
    #     rail cannot happen (a gate-free arm was never routed) and is refused.
    bodies = [[] for _ in rails]
    for idx, r in enumerate(rails):
        while j < len(P) and P[j] and RZ.fullmatch(P[j][0] or "") \
                and len(P[j][1]) == 2 and P[j][1][0] == r:
            if RZ.fullmatch(P[j][0]).group(1) != widths[idx]:
                return None
            bodies[idx].append(P[j][1][1])
            j += 1
        if not bodies[idx]:
            return None

    # (4) the batched route-backs — same legs, same order, same polarity.
    for idx, r in enumerate(rails):
        leg = _route_leg(P, j, r, flag, base)
        if leg is None or leg[1] != negated[idx]:
            return None
        j = leg[0]

    # (5) the batched rail frees.
    for r in rails:
        if j >= len(P) or not P[j] or P[j][0] != "cqrt_free" or P[j][1] != [r]:
            return None
        j += 1

    out, gates = [], 0
    for idx, r in enumerate(rails):
        if negated[idx]:
            out.append("cqrt_x(%s)" % flag)
        for t in bodies[idx]:
            out.append("cqrt_rz_%s_controlled(%s, %s, %s)"
                       % (widths[idx], flag, base, t))
            gates += 1
        if negated[idx]:
            out.append("cqrt_x(%s)" % flag)
    return j, out, len(rails), gates, sum(1 for n in negated if n)


def reduce_routes(lines):
    """Rewrite every routed PHASE region into its control-in-place form.

    -> (reduced_lines, n_regions, n_arms, n_gates, n_negated_arms). A region the
    matcher does not recognize — a 4.3 nest's inner region, a 4.5 switch arm that
    is not a flat region, a method-B value arm — is copied through verbatim, which
    is what lets a mixed golden pass.
    """
    P = [parse(l) for l in lines]
    RS = work_rails(P)
    out, i, nreg, narm, ngate, nneg = [], 0, 0, 0, 0, 0
    while i < len(lines):
        m = match_region(P, i, RS)
        if m:
            j, repl, a, g, ng = m
            out += repl
            nreg += 1
            narm += a
            ngate += g
            nneg += ng
            i = j
            continue
        out.append(lines[i])
        i += 1
    return out, nreg, narm, ngate, nneg


# ─────────────────────────────────────────────────────────────────────────────
# SCOPE (bd drbq Inc 2a round-1 review, L3 F1) — "did the collapse stay inside
# the FLAT path?", asked of the OLD trace.
# ─────────────────────────────────────────────────────────────────────────────

FLAGMINT = re.compile(r"cq_template_(icmp|fcmp)_[A-Za-z0-9_]+$")


def _is_flag_mint(p):
    return bool(p and p[2] and FLAGMINT.fullmatch(p[0] or "")
                and not p[0].endswith("_unc") and not p[0].endswith("_inv"))


def _is_flag_strip(p):
    return bool(p and (p[0] or "").startswith("cq_template_")
                and ((p[0].endswith("_unc") or p[0].endswith("_inv")))
                and re.match(r"cq_template_(icmp|fcmp)_", p[0]) and p[1])


def out_of_scope_signature(lines):
    """-> a reason string if this trace bears a NESTED or SWITCH signature, else None.

    Inc 2a's scope is the FLAT `emitRegion` path; the 4.3 depth-2 nest and the 4.5
    switch KEEP the route. A golden bearing one of those signatures must therefore
    be byte-identical old->new, and `audit()` fails it loudly if it is not.

    (S1) NESTED — a `cqrt_cswap` whose ROUTED BASE is itself a work rail. That is
         the depth-2 nest's inner level and nothing else in the emitted vocabulary
         produces it. Fires on `slice_control_nested_phase`; does NOT fire on
         `slice_control_seq_grover` / `slice_control_seq_regions`, whose bases are
         registers.

    (S2) TWO **CONTROL** FLAGS OPEN AT ONCE — a second flag minted while an
         earlier one is still unstripped, where BOTH are used as a control (arg 0
         of a `cqrt_cswap` or of a `cqrt_r{y,z}_*_controlled`). That is a nest's
         flag-per-level. The "control" restriction is load-bearing and was
         MEASURED: without it the check fired on 30+ unrelated goldens whose
         DERIVED-condition chains legitimately keep two `cq_template_icmp_*`
         results live at once, which would have turned every future edit to one
         of them into a spurious OUT-OF-SCOPE failure.

    ⚠ WHAT THIS DOES **NOT** CATCH, stated because a scope check nobody has
    measured the limits of is worse than none. A 4.5 SWITCH's phase trace is
    structurally INDISTINGUISHABLE from a sequence of flat regions at the trace
    level — measured: `slice_control_switch_phase` (three `icmp_eq` mint / route /
    strip groups on one base, nothing between them) has the same shape as
    `slice_control_seq_regions` (two `icmp_sgt` groups on one base, nothing
    between them), and the second IS in scope and DOES collapse. There is no
    sound trace-only discriminator, so a hypothetical switch collapse would still
    read as `COLLAPSE-ONLY` here. The switch half of the scope split is witnessed
    ELSEWHERE — by the `control_swap_switch_phase*.ll` lit fixtures (which assert
    `cqrt_cswap` positively) and by the whole-corpus census that no module emits
    both a `cqrt_cswap` and a `cqrt_rz_*_controlled`. Do not quote a green run
    here as evidence for it.
    """
    P = [parse(l) for l in lines]
    RS = work_rails(P)
    for p in P:
        if p and p[0] == "cqrt_cswap" and len(p[1]) == 3 and p[1][1] in RS:
            return "nested route: cswap routes base %s, itself a work rail" % p[1][1]
    ctl = set()
    for p in P:
        if not p or not p[1]:
            continue
        n = p[0] or ""
        if n == "cqrt_cswap" or (n.startswith("cqrt_r") and n.endswith("_controlled")):
            ctl.add(p[1][0])
    open_flags = []
    for p in P:
        if _is_flag_mint(p):
            if p[2] in ctl:
                open_flags.append(p[2])
            if len(open_flags) > 1:
                return ("two control flags open at once (%s), a per-level nest "
                        "signature" % ", ".join(open_flags))
        elif _is_flag_strip(p) and p[1] and p[1][0] in open_flags:
            open_flags.remove(p[1][0])
    return None


def strip_handles(lines):
    """Handle-INVARIANT normalisation: every `hN` -> `h`.

    Used only by check (A). Unlike `normalise` (renumber by first appearance) this
    survives the removal of a line that mints a handle, which is exactly what the
    collapse does — so the (A) multiset delta comes out as the collapse arithmetic
    itself rather than as renumbering noise.
    """
    return [HANDLE.sub("h", l) for l in lines]


def expected_delta(old_lines, narm, ngate, nneg):
    """The §9.2 multiset delta the collapse MUST produce, handle-stripped.

    -> (Counter_only_old, Counter_only_new), built from the OLD trace's own
    removed lines so the widths and angles are the real ones rather than a guess.
    """
    P = [parse(l) for l in old_lines]
    RS = work_rails(P)
    only_old, only_new = collections.Counter(), collections.Counter()
    i = 0
    while i < len(old_lines):
        m = match_region(P, i, RS)
        if not m:
            i += 1
            continue
        j, repl, _a, _g, _n = m
        for l in strip_handles(old_lines[i:j]):
            only_old[l] += 1
        for l in strip_handles(repl):
            only_new[l] += 1
        i = j
    common = only_old & only_new
    return only_old - common, only_new - common


def git_show(rev, path):
    r = subprocess.run(["git", "show", "%s:%s" % (rev, path)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return r.stdout.splitlines()


def _fmt_counter(c, cap=8):
    items = sorted(c.items())
    body = ", ".join("%s x%d" % (k, v) for k, v in items[:cap])
    if len(items) > cap:
        body += ", … (%d more)" % (len(items) - cap)
    return "%d line(s) [%s]" % (sum(c.values()), body)


def audit(path, rev):
    """-> (status, detail, k_regions, k_arms, k_gates) for one committed golden.

    No `verbose` parameter: the (A) delta is printed unconditionally now (the
    round-1 review's L3 F9 — a check nobody sees is a check nobody runs), so there
    is nothing left for a verbosity flag to reveal here. `--verbose` still governs
    the per-mutant detail in `--selftest`.
    """
    old = git_show(rev, path)
    if old is None:
        return "NEW-FILE", "not present at %s" % rev, 0, 0, 0
    return audit_pair(old, open(path).read().splitlines())


def audit_pair(old, new):
    """-> (status, detail, k_regions, k_arms, k_gates).

    Three checks, all ENFORCED (bd drbq Inc 2a round-1 review, L3 F1/F9):
      (S) SCOPE   — an out-of-scope (nested / switch) signature in the OLD trace
                    means the golden must be byte-identical old->new.
      (A) MULTISET — the §9.2 delta, handle-INVARIANT, must be exactly the
                    collapse arithmetic the reducer performed and nothing else.
                    Printed on EVERY audited golden, verbose or not.
      (B) STRUCTURAL — reduced-old must equal new line for line (order-sensitive).
    """
    # (S) SCOPE, asked FIRST and asked of the OLD trace, so it is answered even
    #     for a golden that did not move (where the answer is the assertion).
    scope = out_of_scope_signature(old)
    if old == new:
        d = "out-of-scope signature present and correctly UNCHANGED: %s" % scope \
            if scope else ""
        return "UNCHANGED", d, 0, 0, 0
    if scope:
        return ("OUT-OF-SCOPE",
                "this golden MOVED but bears a 4.3-nest signature, which Inc 2a "
                "does not collapse — %s" % scope, 0, 0, 0)

    red, nreg, narm, ngate, nneg = reduce_routes(old)
    rn, nn = normalise(red), normalise(new)

    # (A) THE §9.2 MULTISET DELTA, handle-INVARIANT and ENFORCED. `strip_handles`
    #     (every `hN` -> `h`) rather than `normalise` (renumber by first
    #     appearance), because the collapse DELETES a handle-minting line and
    #     first-appearance renumbering therefore shifts every later handle — which
    #     buries the arithmetic §9.2 asks for under renumbering noise. The
    #     observed delta must equal the delta the reducer itself performed: if
    #     they differ, the trace moved somewhere the reduction did not touch.
    co = collections.Counter(strip_handles(old))
    cn = collections.Counter(strip_handles(new))
    obs_old, obs_new = co - cn, cn - co
    exp_old, exp_new = expected_delta(old, narm, ngate, nneg)
    delta = ("  (A) observed  -%s\n      observed  +%s\n"
             "      expected  -%s\n      expected  +%s"
             % (_fmt_counter(obs_old), _fmt_counter(obs_new),
                _fmt_counter(exp_old), _fmt_counter(exp_new)))
    a_ok = (obs_old == exp_old and obs_new == exp_new)

    # (A2) CSWAP ACCOUNTING — exactly two per collapsed arm removed, none moved.
    n_cs_old = sum(1 for l in old if l.startswith("cqrt_cswap("))
    n_cs_new = sum(1 for l in new if l.startswith("cqrt_cswap("))
    cs_ok = (n_cs_old - n_cs_new == 2 * narm)
    delta += ("\n  (A2) cqrt_cswap %d -> %d (removed %d, expected 2 x %d arm(s))"
              % (n_cs_old, n_cs_new, n_cs_old - n_cs_new, narm))

    # (B) the strict order-sensitive check.
    b_ok = (rn == nn)

    if a_ok and cs_ok and b_ok:
        return "COLLAPSE-ONLY", delta, nreg, narm, ngate

    parts = []
    if not b_ok:
        i = next((k for k in range(max(len(rn), len(nn)))
                  if k >= len(rn) or k >= len(nn) or rn[k] != nn[k]), 0)
        parts.append("(B) reduced-old != new at line %d\n     reduced-old: %s\n"
                     "     new        : %s"
                     % (i + 1,
                        rn[i] if i < len(rn) else "<end>",
                        nn[i] if i < len(nn) else "<end>"))
    if not a_ok:
        parts.append("(A) multiset delta is NOT the reducer's own collapse")
    if not cs_ok:
        parts.append("(A2) cqrt_cswap accounting is off")
    return "FINDING", "\n     ".join(parts) + "\n" + delta, nreg, narm, ngate



# ═════════════════════════════════════════════════════════════════════════════
# --selftest — THE AUDIT'S OWN MUTANT VALIDATION (bd drbq Inc 2a round-1 review,
# L3 F1/F5/F9). "A checker nobody has tried to fool is a checker nobody should
# trust" — the same standard `tools/free_pairing_check_test.py` is held to.
#
# Every mutant below is applied to the NEW trace of an EMBEDDED (old, new) pair
# taken verbatim from the committed goldens, so the selftest needs no git, no
# build and no test tree. A mutant that comes back `COLLAPSE-ONLY` is a SURVIVOR
# and fails the run.
# ═════════════════════════════════════════════════════════════════════════════

# slice_control_phase_diamond — ONE non-negated arm, TWO gates.
_OLD_DIAMOND = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cqrt_rz_i32(h2, 0x1.8p-1)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_DIAMOND = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_rz_i32_controlled(h1, h0, 0x1.8p-1)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# slice_control_phase_ifne — ONE NEGATED arm (the `cqrt_x` bracket arithmetic:
# the route carries FOUR `cqrt_x`, control-in-place TWO).
_OLD_IFNE = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_x(h1)
cqrt_cswap(h1, h0, h2)
cqrt_x(h1)
cqrt_rz_i32(h2, 0x1p-2)
cqrt_x(h1)
cqrt_cswap(h1, h0, h2)
cqrt_x(h1)
cqrt_free(h2)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_IFNE = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_x(h1)
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_x(h1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# slice_control_seq_regions — TWO regions, so TWO flag frees (the aliasing probe).
_OLD_SEQ = """cqrt_alloc_i32(7) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cq_template_icmp_sgt_i32_hl(h0, 3) -> h3
cqrt_alloc_i32(0) -> h4
cqrt_cswap(h3, h0, h4)
cqrt_rz_i32(h4, 0x1.8p-1)
cqrt_cswap(h3, h0, h4)
cqrt_free(h4)
cq_template_icmp_sgt_i32_hl_unc(h3, h0, 3)
cqrt_free(h3)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_SEQ = """cqrt_alloc_i32(7) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cq_template_icmp_sgt_i32_hl(h0, 3) -> h2
cqrt_rz_i32_controlled(h2, h0, 0x1.8p-1)
cq_template_icmp_sgt_i32_hl_unc(h2, h0, 3)
cqrt_free(h2)
cqrt_measure_i32(h0) -> 0""".splitlines()

# slice_control_nested_phase — the 4.3 depth-2 nest, which Inc 2a does NOT
# collapse. The OUT-OF-SCOPE mutant collapses its INNER region.
_OLD_NEST = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cq_template_icmp_slt_i32_hl(h2, 9) -> h3
cqrt_alloc_i32(0) -> h4
cqrt_cswap(h3, h2, h4)
cqrt_rz_i32(h4, 0x1.8p-1)
cqrt_cswap(h3, h2, h4)
cqrt_free(h4)
cq_template_icmp_slt_i32_hl_unc(h3, h2, 9)
cqrt_free(h3)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_NEST_INNER_COLLAPSED = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cq_template_icmp_slt_i32_hl(h2, 9) -> h3
cqrt_rz_i32_controlled(h3, h2, 0x1.8p-1)
cq_template_icmp_slt_i32_hl_unc(h3, h2, 9)
cqrt_free(h3)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()


def _mv(L, frm, to):
    L = list(L)
    x = L.pop(frm)
    L.insert(to, x)
    return L


def _swap(L, a, b):
    L = list(L)
    L[a], L[b] = L[b], L[a]
    return L


def _drop(L, i):
    L = list(L)
    del L[i]
    return L


def _first(L, sub):
    return next(i for i, l in enumerate(L) if sub in l)


def _mutants():
    """-> [(name, old_lines, new_lines, note)] — L3's 20-mutant family."""
    D, ND = _OLD_DIAMOND, _NEW_DIAMOND
    F, NF = _OLD_IFNE, _NEW_IFNE
    S, NS = _OLD_SEQ, _NEW_SEQ
    g0 = _first(ND, "cqrt_rz_i32_controlled")          # 3
    unc = _first(ND, "_hl_unc")                        # 5
    out = []
    # ── a: ORDER ────────────────────────────────────────────────────────────
    out.append(("a1  cRz moved one line earlier", D, _mv(ND, g0, g0 - 1)))
    out.append(("a2  cRz moved past the flag strip", D, _mv(ND, g0, unc)))
    out.append(("a3  the two cRz of one spine swapped", D, _swap(ND, g0, g0 + 1)))
    out.append(("a4  two post-region lines swapped", D, _swap(ND, unc, unc + 1)))
    # ── b: ANGLE ────────────────────────────────────────────────────────────
    out.append(("b   theta changed 0x1p-2 -> 0x1p-3", D,
                [l.replace("0x1p-2", "0x1p-3") for l in ND]))
    # ── c: OPERANDS ─────────────────────────────────────────────────────────
    out.append(("c1  flag/handle SWAPPED in the cRz", D,
                [l.replace("(h1, h0,", "(h0, h1,") if "controlled" in l else l
                 for l in ND]))
    out.append(("c2  base -> a different live handle", D,
                [l.replace("(h1, h0,", "(h1, h1,") if "controlled" in l else l
                 for l in ND]))
    out.append(("c3  flag -> a different live handle", D,
                [l.replace("(h1, h0,", "(h0, h0,") if "controlled" in l else l
                 for l in ND]))
    # ── d/e: DELETION / EXTRA TRAFFIC ───────────────────────────────────────
    out.append(("d   the flag strip deleted", D, _drop(ND, unc)))
    out.append(("e1  extra cqrt_free appended", D, list(ND) + ["cqrt_free(h0)"]))
    out.append(("e2  extra cqrt_free mid-stream", D,
                ND[:g0] + ["cqrt_free(h0)"] + ND[g0:]))
    # ── f: THE cqrt_x BRACKET ARITHMETIC (negated arm) ──────────────────────
    xs = [i for i, l in enumerate(NF) if l.startswith("cqrt_x(")]
    out.append(("f1  one cqrt_x bracket dropped", F, _drop(NF, xs[0])))
    out.append(("f2  both cqrt_x brackets dropped", F,
                [l for l in NF if not l.startswith("cqrt_x(")]))
    out.append(("f3  an extra cqrt_x bracket added", F,
                NF[:xs[0]] + ["cqrt_x(h1)"] + NF[xs[0]:]))
    # ── g: THE ARM GATES THEMSELVES ─────────────────────────────────────────
    out.append(("g1  both arm gates dropped", D,
                [l for l in ND if "controlled" not in l]))
    out.append(("g2  one arm gate dropped", D, _drop(ND, g0)))
    # ── h: FREE ALIASING (needs two frees) ──────────────────────────────────
    fs = [i for i, l in enumerate(NS) if l.startswith("cqrt_free(")]
    out.append(("h   cqrt_free targets permuted", S, _swap(NS, fs[0], fs[1])))
    # ── i/j: STEM AND WIDTH ─────────────────────────────────────────────────
    out.append(("i   stem rz -> ry in the cRz", D,
                [l.replace("cqrt_rz_i32_controlled", "cqrt_ry_i32_controlled")
                 for l in ND]))
    out.append(("j   width i32 -> i64 in the cRz", D,
                [l.replace("cqrt_rz_i32_controlled", "cqrt_rz_i64_controlled")
                 for l in ND]))
    return out


def selftest(verbose=False):
    """-> exit code. 20 mutants + 4 controls + 1 out-of-scope probe."""
    print("=== CONTROLS (must be COLLAPSE-ONLY / UNCHANGED) ===")
    bad = 0
    controls = [("diamond (1 arm, 2 gates)", _OLD_DIAMOND, _NEW_DIAMOND, "COLLAPSE-ONLY"),
                ("ifne (1 NEGATED arm, 1 gate)", _OLD_IFNE, _NEW_IFNE, "COLLAPSE-ONLY"),
                ("seq_regions (2 regions)", _OLD_SEQ, _NEW_SEQ, "COLLAPSE-ONLY"),
                ("nested_phase, unchanged", _OLD_NEST, _OLD_NEST, "UNCHANGED")]
    for name, o, n, want in controls:
        st, detail, _r, _a, _g = audit_pair(o, n)
        ok = (st == want)
        bad += 0 if ok else 1
        print("  %-40s %-14s %s" % (name, st, "ok" if ok else "*** WRONG (want %s) ***" % want))
        if detail and (verbose or not ok):
            print("     " + detail.replace("\n", "\n     "))

    print("\n=== SCOPE PROBE (the L3 F1 gap) ===")
    st, detail, _r, _a, _g = audit_pair(_OLD_NEST, _NEW_NEST_INNER_COLLAPSED)
    ok = (st != "COLLAPSE-ONLY")
    bad += 0 if ok else 1
    print("  %-40s %-14s %s" % ("4.3 nest, INNER region collapsed", st,
                                "DETECTED" if ok else "*** SURVIVED ***"))
    if detail:
        print("     " + detail.replace("\n", "\n     "))

    print("\n=== MUTANTS (every one must be a FINDING) ===")
    for name, o, n in _mutants():
        st, detail, _r, _a, _g = audit_pair(o, n)
        ok = (st != "COLLAPSE-ONLY")
        bad += 0 if ok else 1
        print("  %-40s %-14s %s" % (name, st, "DETECTED" if ok else "*** SURVIVED ***"))
        if verbose or not ok:
            print("     " + (detail or "").replace("\n", "\n     "))

    n = len(_mutants())
    print("\n=== SELFTEST: %d mutant(s) + %d control(s) + 1 scope probe — %s ==="
          % (n, len(controls),
             "PASS, 0 survivors" if bad == 0 else "FAIL, %d problem(s)" % bad))
    return 1 if bad else 0

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("goldens", nargs="*",
                    help="paths to audit (default: every CHANGED tests/e2e golden)")
    ap.add_argument("--rev", default="HEAD",
                    help="git revision holding the OLD goldens (default HEAD)")
    ap.add_argument("--all", action="store_true",
                    help="audit every tests/e2e golden, not only the changed ones")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--selftest", action="store_true",
                    help="run the audit's own mutant validation (needs no git, "
                         "no build, no test tree) and exit")
    cfg = ap.parse_args()

    if cfg.selftest:
        return selftest(cfg.verbose)

    paths = cfg.goldens
    if not paths:
        if cfg.all:
            paths = sorted(p for p in os.listdir("tests/e2e")
                           if p.endswith(".expected.log"))
            paths = [os.path.join("tests/e2e", p) for p in paths]
        else:
            # CHANGED **and** UNTRACKED (bd drbq Inc 2a round-1 review, L3 F5).
            # `git diff --name-only` lists only TRACKED modifications, so a
            # brand-new golden — exactly the one nobody has ever audited — was
            # silently skipped, and its `NEW-FILE` status could only ever appear
            # when a path was passed explicitly. Measured: `git diff --name-only
            # HEAD -- tools` omitted the then-untracked
            # `tools/golden_multiset_audit.py` itself.
            r = subprocess.run(["git", "diff", "--name-only", cfg.rev, "--",
                                "tests/e2e"], capture_output=True, text=True)
            u = subprocess.run(["git", "ls-files", "--others",
                                "--exclude-standard", "--", "tests/e2e"],
                               capture_output=True, text=True)
            paths = sorted({p for p in (r.stdout + "\n" + u.stdout).split()
                            if p.endswith(".expected.log")})
    if not paths:
        print("golden_multiset_audit: no goldens to audit")
        return 0

    bad = 0
    tally = collections.Counter()
    treg = tarm = tgate = 0
    for p in sorted(paths):
        st, detail, nreg, narm, ngate = audit(p, cfg.rev)
        tally[st] += 1
        treg += nreg
        tarm += narm
        tgate += ngate
        mark = "!!" if st in ("FINDING", "OUT-OF-SCOPE") else "  "
        extra = ""
        if st == "COLLAPSE-ONLY":
            extra = "  k=%d region(s), %d arm(s), %d gate(s)" % (nreg, narm, ngate)
        print("%s %-58s %s%s" % (mark, os.path.basename(p), st, extra))
        if detail:
            print("     " + detail.replace("\n", "\n     "))
        if st in ("FINDING", "OUT-OF-SCOPE"):
            bad += 1

    print("\n=== TALLY (%d golden(s) vs %s) ===" % (len(paths), cfg.rev))
    for k, v in sorted(tally.items()):
        print("  %-16s %d" % (k, v))
    print("  routes collapsed: %d region(s), %d arm(s), %d rz gate(s)"
          % (treg, tarm, tgate))
    print("  %s" % ("PASS — every diff is the collapse and nothing else"
                    if bad == 0 else "FAIL — %d golden(s) moved otherwise" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
