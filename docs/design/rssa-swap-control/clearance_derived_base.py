#!/usr/bin/env python3
"""
Rule-13 statevector clearance — DERIVED-base swap-route (test_C_libtooling-9hh).

DESIGN-LEVEL oracle (see bd memory `rule13-no-backend-clearance-scope`): there
is no execution backend, so this hand-translates the construction the emitter
produces — pinned by tests/e2e/slice_control_phase_ifelse_derived.expected.log —
into the prototype_semantics.py simulator and verifies the unitary there. It
does NOT verify the compiled artifact; emitter fidelity is covered separately
by the lit fixtures' structural probes and the golden trace diff.

CLAIM CLEARED: routing a DERIVED base handle — a pre-region, unconditional
`cq_phi` (Rz) result `%qd = cq_phi(%q,·)` shared by both arm spines — through
the §5b dual-rail swap-route stream is coherence-exact:

    q = RY(gamma)|0>                      # cq_theta — the taint source
    q = Rz(pre) q                         # PRE-REGION derived rotation (NEW)
    flag  = [basis(q) == 1]               # cq_template_icmp_*_hl  (CNOT model)
    cswap(flag; q, T); ~flag-bracketed cswap(flag; q, E)      # route-in
    Rz(a1) Rz(a2) on T;  Rz(b) on E       # arm bodies, VERBATIM, UNCONTROLLED
    route-back (adjoint of the split)     # same cswap pairs, same flag
    free T, free E                        # MUST be exactly |0> in population
    flag ^= [basis(q) == 1]               # icmp_inv strip — q's basis unchanged
    free flag                             # MUST be exactly |0> in population

checked against the CONTRACT ideal — the project convention diag(1, e^{i th}),
under which the inactive arm contributes nothing (Rz|0> = |0>): per basis value
k, relative phase = pre + (k==1 ? a1+a2 : 0). The stream is run under BOTH Rz
conventions:

  * project convention   diag(1, e^{i th})            (the shipped runtime)
  * symmetric convention diag(e^{-i th/2}, e^{+i th/2}) (hardware Rz)

per the diagonality invariant (bd memory `rz-diag-flag-strip-invariant`): the
load-bearing property is that the pre-region gate and every arm gate are
DIAGONAL, not the specific phase convention.

TWO-ARM convention-independence (a STRONGER fact than the single-arm memory
case, found while authoring this clearance): in the swap-route stream each
arm's gate ALWAYS fires (uncontrolled, on its rail), and the inactive arm's
rail holds |0> on BOTH branches — so under symmetric Rz the inactive arm's
e^{-i th/2} is branch-INDEPENDENT (global), and the active arm's +-th/2 halves
combine to the full relative th. The stream therefore equals the CONTRACT
semantics up to global phase under ANY diagonal convention. (A symmetric-Rz
CONTROLLED-OP reference genuinely differs for two content arms — there the
inactive gate does not fire at all, so the else phase on |0> becomes
observable relative phase. The swap-route stream does not have that
convention sensitivity; fidelity is taken as |<ideal|final>|, which discards
the global factor.)

Why the pre-region gate cannot break the flag: the flag is minted from
basis(q), and Rz is diagonal, so basis(q) after the pre-rotation equals
basis(q) before it — the flag a stale-condition variant (icmp on the theta
result) mints is the SAME flag, which is why both fixture variants accept.

NEGATIVE probes (the test must have teeth). Precision matters here (§8 review
corrected an earlier mis-statement): a basis-permuting gate STRICTLY BEFORE the
flag mint does NOT break the strip — mint and strip both read the
post-permutation basis, so they cancel; what a pre-mint permutation (or Ry)
breaks is mint-equals-SOURCE-COMPARE when the source compare PRECEDES it (the
chained-Ry stale-condition miscompile — probed below as a fidelity-vs-source
failure with a CLEAN flag, which is exactly why it is verify-clean and
trace-plausible). The strip itself breaks only for a basis change BETWEEN mint
and strip (probed: flag pop 1.0) or an off-diagonal ARM gate (probed: dirty
rail). Diagonality of the pre-region gate is load-bearing for
mint == source-compare; diagonality of the ARM gates is load-bearing for
rail-|0> and mint == strip.

MULTI-BIT GENERALITY: the 1-qubit model is degenerate in two ways (the else
arm only ever sees |0> in its rail, hiding the else angle; and the
convention-independence argument looks rail-specific). multibit_clear() runs an
independent 2-bit-register model — general basis predicate P(k) = k >= 2,
register-level diagonal conventions (project e^{i th k} and an offset
convention with d(0) != 1), random input state — and re-verifies: stream ==
contract ideal exactly (project) / up to global phase (offset), rails + flag
exactly clean, stale-vs-live mint identical (diagonal pre-rotation commutes
with any basis predicate), and the else angle IS observable and tracked
correctly. The general convention-independence argument: every diagonal gate
factors as scalar(th) x (d(0)=1 form), and in the swap-route stream every arm
gate fires exactly once on EVERY branch, so the scalars accumulate
branch-independently — truly global.

Run:  python3 clearance_derived_base.py     (one-off; NOT in the build)
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prototype_semantics import (  # noqa: E402
    RY, X, apply_cswap, dist_qubit, op_1q, op_c1q, zero_state,
)

# Qubit layout (qubit 0 = MSB, prototype_semantics convention).
Q, FLAG, T, E = 0, 1, 2, 3
N = 4


def rz_project(th):
    """The shipped runtime convention: diag(1, e^{i th})."""
    return np.diag([1.0, np.exp(1j * th)]).astype(complex)


def rz_symmetric(th):
    """The hardware convention: diag(e^{-i th/2}, e^{+i th/2})."""
    return np.diag([np.exp(-1j * th / 2), np.exp(1j * th / 2)]).astype(complex)


def cnot(ctrl, tgt, n):
    """flag ^= [basis(ctrl) == 1] — the 1-qubit model of the icmp_hl template
    (and of its _inv twin: the predicate is self-inverse under XOR)."""
    return op_c1q(X, ctrl, tgt, n)


def run_stream(rz, pre, a1, a2, b, gamma, pre_gate=None, arm_gate=None):
    """The emitted stream, line for line from the golden trace. `pre_gate` /
    `arm_gate` override the pre-region / first-then-arm gate for the negative
    probes; default is the honest Rz."""
    s = zero_state(N)
    s = op_1q(RY(gamma), Q, N) @ s                       # cqrt_ry (theta)
    s = op_1q(pre_gate if pre_gate is not None
              else rz(pre), Q, N) @ s                    # PRE-REGION cqrt_rz
    s = cnot(Q, FLAG, N) @ s                             # flag mint
    s = apply_cswap(s, FLAG, Q, T, N)                    # route-in: then rail
    s = op_1q(X, FLAG, N) @ s
    s = apply_cswap(s, FLAG, Q, E, N)                    # route-in: else rail
    s = op_1q(X, FLAG, N) @ s
    s = op_1q(arm_gate if arm_gate is not None
              else rz(a1), T, N) @ s                     # then gate 1
    s = op_1q(rz(a2), T, N) @ s                          # then gate 2
    s = op_1q(rz(b), E, N) @ s                           # else gate
    s = apply_cswap(s, FLAG, Q, T, N)                    # route-back (adjoint)
    s = op_1q(X, FLAG, N) @ s
    s = apply_cswap(s, FLAG, Q, E, N)
    s = op_1q(X, FLAG, N) @ s
    rail_t_pop = dist_qubit(s, T, N)[1]                  # free T: must be |0>
    rail_e_pop = dist_qubit(s, E, N)[1]                  # free E: must be |0>
    s = cnot(Q, FLAG, N) @ s                             # icmp_inv strip
    flag_pop = dist_qubit(s, FLAG, N)[1]                 # free flag: must be |0>
    return s, rail_t_pop, rail_e_pop, flag_pop


def ideal_state(pre, a1, a2, b, gamma):
    """CONTRACT ideal on q (rails/flag exactly |0>), in the project convention
    diag(1, e^{i th}) — the runtime ABI semantics: per basis value k, the arm
    selected by k fires and the other contributes nothing (Rz|0> = |0>), so
    phase(k=0) = 0 (pre and else both act on |0>) and
    phase(k=1) = pre + a1 + a2. The else angle `b` is unobservable on a 1-qubit
    q under the contract — exactly Rz_proj(b)|0> = |0>. The stream under EITHER
    convention must match this up to a global phase (|vdot| discards it)."""
    del b  # unobservable under the contract on a 1-qubit q (see docstring).
    amp = RY(gamma) @ np.array([1.0, 0.0], dtype=complex)
    full = np.zeros(2 ** N, dtype=complex)
    full[0b0000] = amp[0]                                # |q=0, flag/T/E = 0>
    full[0b1000] = amp[1] * np.exp(1j * (pre + a1 + a2))  # |q=1, ...>
    return full


def clear(name, rz):
    pre, a1, a2, b, gamma = 0.9, 0.25, 0.125, 0.75, 1.1
    s, pt, pe, pf = run_stream(rz, pre, a1, a2, b, gamma)
    ideal = ideal_state(pre, a1, a2, b, gamma)
    fid = abs(np.vdot(ideal, s))
    print(f"  [{name}] rail_T |1>-pop = {pt:.3e}   rail_E |1>-pop = {pe:.3e}   "
          f"flag |1>-pop = {pf:.3e}   |<ideal|final>| = {fid:.12f}")
    assert pt < 1e-12 and pe < 1e-12, "rail not |0> at free — hidden measurement"
    assert pf < 1e-12, "flag not |0> after icmp_inv strip"
    assert abs(fid - 1.0) < 1e-12, "q decohered / wrong phase vs ideal"


def negative_probes():
    rz = rz_project
    pre, a1, a2, b, gamma = 0.9, 0.25, 0.125, 0.75, 1.1
    # (1) basis change BETWEEN mint and strip: the strip reads a different basis
    # than the mint and MISSES (this — not a pre-mint permutation — is what
    # breaks the strip; a pre-mint X commutes through to both).
    s = zero_state(N)
    s = op_1q(RY(gamma), Q, N) @ s
    s = op_1q(rz(pre), Q, N) @ s
    s = cnot(Q, FLAG, N) @ s
    s = op_1q(X, Q, N) @ s                               # basis flip mid-region
    s = cnot(Q, FLAG, N) @ s                             # strip now MISSES
    pf = dist_qubit(s, FLAG, N)[1]
    print(f"  [negative: basis flip between mint and strip] flag |1>-pop = {pf:.6f}")
    assert pf > 0.1, "negative probe failed to dirty the flag — test has no teeth"
    # (2) OFF-DIAGONAL arm gate (RY on the then rail): rail dirty at free.
    s, pt, pe, pf = run_stream(rz, pre, a1, a2, b, gamma, arm_gate=RY(0.7))
    print(f"  [negative: RY arm body] rail_T |1>-pop = {pt:.6f}")
    assert pt > 0.01, "negative probe failed to dirty the rail — test has no teeth"
    # (3) CHAINED-Ry STALE CONDITION (the verify-clean one): the source compares
    # BEFORE a chained Ry, but the emitter mints at the BRANCH (after it). Mint
    # and strip still agree (both post-Ry) — the flag comes back CLEAN — yet the
    # arm fired on the wrong predicate: fidelity vs the SOURCE semantics < 1
    # with NO dirty rail/flag to betray it. This is why the pass now declines
    # "condition predates a non-diagonal gate" (the trace is plausible, the
    # unitary is wrong — undetectable by every population assertion above).
    t2 = 0.8
    s = zero_state(N)
    s = op_1q(RY(gamma), Q, N) @ s                       # theta
    s = op_1q(RY(t2), Q, N) @ s                          # chained Ry AFTER the source compare
    s = cnot(Q, FLAG, N) @ s                             # emitter mints at the BRANCH
    s = apply_cswap(s, FLAG, Q, T, N)
    s = op_1q(rz(a1), T, N) @ s
    s = apply_cswap(s, FLAG, Q, T, N)
    s = cnot(Q, FLAG, N) @ s                             # strip: post-Ry too -> CLEAN
    pf = dist_qubit(s, FLAG, N)[1]
    # SOURCE semantics: flag minted at the COMPARE (pre-Ry), then Ry, then the
    # controlled phase on the pre-Ry predicate.
    i = zero_state(N)
    i = op_1q(RY(gamma), Q, N) @ i
    i = cnot(Q, FLAG, N) @ i                             # compare position
    i = op_1q(RY(t2), Q, N) @ i
    i = op_c1q(rz(a1), FLAG, Q, N) @ i                   # arm on the SOURCE flag
    i = cnot(Q, FLAG, N) @ i                             # (source strip would miss
    #                                                       too — the shape has no
    #                                                       sound lowering at all)
    fid = abs(np.vdot(i, s))
    print(f"  [negative: chained-Ry stale cond] flag |1>-pop = {pf:.6f}   "
          f"|<source|emitted>| = {fid:.6f}")
    assert pf < 1e-12, "expected a CLEAN flag — that is what makes it silent"
    assert fid < 0.99, "stale-cond probe failed to diverge — test has no teeth"


# ---------------------------------------------------------------------------
# Multi-bit generality (§8 review): 2-bit register q, predicate P(k) = k >= 2,
# register-level diagonal conventions, random input state. Layout:
# idx = ((q*4 + t)*4 + e)*2 + f over q,t,e in 0..3, f in 0..1 (128 dims).
# ---------------------------------------------------------------------------
def _mb_index(q, t, e, f):
    return ((q * 4 + t) * 4 + e) * 2 + f


def _mb_map(state, fn):
    out = np.zeros_like(state)
    for q in range(4):
        for t in range(4):
            for e in range(4):
                for f in range(2):
                    src = _mb_index(q, t, e, f)
                    dst, phase = fn(q, t, e, f)
                    out[dst] += phase * state[src]
    return out


def multibit_clear(name, d):
    """`d(th, k)` = the register Rz convention's phase factor on basis |k>."""
    rng = np.random.default_rng(7)
    pre, a1, a2, b = 0.9, 0.25, 0.125, 0.75
    P = lambda k: int(k >= 2)                            # the icmp predicate
    amp = rng.normal(size=4) + 1j * rng.normal(size=4)
    amp /= np.linalg.norm(amp)

    def run(mint_stale):
        s = np.zeros(128, dtype=complex)
        for k in range(4):
            s[_mb_index(k, 0, 0, 0)] = amp[k]            # q random, t=e=0, f=0
        if mint_stale:                                   # stale: mint BEFORE pre-Rz
            s = _mb_map(s, lambda q, t, e, f: (_mb_index(q, t, e, f ^ P(q)), 1))
        s = _mb_map(s, lambda q, t, e, f: (_mb_index(q, t, e, f), d(pre, q)))
        if not mint_stale:                               # live: mint AFTER pre-Rz
            s = _mb_map(s, lambda q, t, e, f: (_mb_index(q, t, e, f ^ P(q)), 1))
        s = _mb_map(s, lambda q, t, e, f:                # route-in: then rail
                    (_mb_index(t, q, e, f) if f else _mb_index(q, t, e, f), 1))
        s = _mb_map(s, lambda q, t, e, f:                # route-in: else (¬f)
                    (_mb_index(e, t, q, f) if not f else _mb_index(q, t, e, f), 1))
        s = _mb_map(s, lambda q, t, e, f: (_mb_index(q, t, e, f), d(a1, t) * d(a2, t)))
        s = _mb_map(s, lambda q, t, e, f: (_mb_index(q, t, e, f), d(b, e)))
        s = _mb_map(s, lambda q, t, e, f:                # route-back (adjoint)
                    (_mb_index(t, q, e, f) if f else _mb_index(q, t, e, f), 1))
        s = _mb_map(s, lambda q, t, e, f:
                    (_mb_index(e, t, q, f) if not f else _mb_index(q, t, e, f), 1))
        dirty = sum(abs(s[_mb_index(q, t, e, f)]) ** 2
                    for q in range(4) for t in range(4) for e in range(4)
                    for f in range(2) if t or e)
        s = _mb_map(s, lambda q, t, e, f: (_mb_index(q, t, e, f ^ P(q)), 1))  # strip
        flag = sum(abs(s[_mb_index(q, t, e, 1)]) ** 2
                   for q in range(4) for t in range(4) for e in range(4))
        return s, dirty, flag

    # Contract ideal (project convention d0): per k the selected arm's phases.
    d0 = lambda th, k: np.exp(1j * th * k)               # project: d0(th,0)=1
    ideal = np.zeros(128, dtype=complex)
    for k in range(4):
        ph = d0(pre, k) * (d0(a1, k) * d0(a2, k) if P(k) else d0(b, k))
        ideal[_mb_index(k, 0, 0, 0)] = amp[k] * ph

    s, dirty, flag = run(mint_stale=False)
    s2, _, _ = run(mint_stale=True)
    fid = abs(np.vdot(ideal, s))
    stale_diff = float(np.max(np.abs(s - s2)))
    print(f"  [multibit {name}] rails-dirty = {dirty:.3e}   flag |1>-pop = {flag:.3e}   "
          f"|<ideal|final>| = {fid:.12f}   stale-vs-live mint |diff| = {stale_diff:.3e}")
    assert dirty < 1e-12 and flag < 1e-12, "multibit: rail/flag not clean at free"
    assert abs(fid - 1.0) < 1e-12, "multibit: stream != contract ideal"
    assert stale_diff < 1e-12, "multibit: stale mint != live mint under a diagonal pre-gate"


if __name__ == "__main__":
    print("Rule-13 clearance: DERIVED-base swap-route (test_C_libtooling-9hh)")
    clear("project Rz  diag(1, e^{i th})          ", rz_project)
    clear("symmetric Rz diag(e^{-i th/2}, e^{+i th/2})", rz_symmetric)
    multibit_clear("project e^{i th k}     ", lambda th, k: np.exp(1j * th * k))
    multibit_clear("offset  e^{i th (k-3/2)}",
                   lambda th, k: np.exp(1j * th * (k - 1.5)))
    negative_probes()
    print("PASS: derived-base routing is coherence-exact (1-qubit AND 2-bit "
          "register,\n      both Rz conventions, stale and live mint); rails "
          "and flag are exactly |0>\n      at every free; negative probes have "
          "teeth (incl. the verify-clean\n      chained-Ry stale-cond shape "
          "the pass now declines).")
