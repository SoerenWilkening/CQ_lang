#!/usr/bin/env python3
"""
Design investigation — mint the control flag at the COMPARE's program point
(test_C_libtooling-ee5).  One-off statevector oracle, NOT in the build; style
follows clearance_derived_base.py.  Design-of-record: MINT_AT_COMPARE.md.

THE SHAPE (clearance_derived_base.py negative probe 3, declined today by
ArmClassify "condition predates a non-diagonal gate"):

    q = cq_theta(u0, gamma)        # Ry(gamma) — taint source
    c = (q > 5)                    # source compare: predicate of the PRE-Ry basis
    q = cq_theta(q, t2)            # chained, in-place, NON-diagonal Ry
    if (c) { q = cq_phi(q, a) }    # phase arm on the STALE predicate
    measure(q)

SOURCE SEMANTICS (the project's own taint contract): a tainted icmp lowers to
the reversible template — an entangling predicate copy into a fresh flag rail
AT THE COMPARE's wire state.  The source unitary is therefore

    U_src = CRz(a)[f->q] . Ry(t2)[q] . MINT[q->f] . Ry(gamma)[q]

and its final state is ENTANGLED between f and q (probe P6: purity < 1).

WHAT THIS FILE PROVES (each probe asserts an exact closed form):

  P1  mint-at-compare + swap-route, flag LEAKED (never stripped, never freed)
      is source-EXACT: fidelity 1.0 to machine precision, rails exactly |0>.
      Right-arm selection is fixed by mint position alone.
  P2  mint-at-BRANCH (what the emitter would do without the guard) diverges:
      stream-vs-stream fidelity = cos^2(t2/2) = 0.848 — reproduces clearance
      probe 3 with a clean flag (the verify-clean silent miscompile).
  P3  mint-at-compare + the 4.1 icmp_inv strip: residual flag P(1) =
      sin^2(t2/2) = 0.152 — the strip reads the post-Ry basis and MISSES.
      (Arm-class-INDEPENDENT: same residual with no arm at all.)
  P4  Bennett-style CONJUGATED strip — Ry(-t2); icmp_inv; Ry(t2) — residual
      flag P(1) = sin^2(gamma/2) sin^2(t2) sin^2(a/2) != 0: the strip window
      does NOT commute with the arm's phase (failure term
      u = cos(t2/2) sin(t2/2) (e^{ia}-1)).  Fails for every phase arm.
  P5  full reverse-play (CRz†, Ry†), strip, replay: flag exactly |0> but the
      arm is ERASED (the replayed CRz sees a |0> control) — fidelity
      cos^2(gamma/2) = 0.727 vs source.  Strip-clean != sound.
  P6  THE THEOREM.  purity(rho_q^src) = 1 - 2 a^2 b^2 (1-|u|^2) < 1, so the
      source marginal on q is MIXED; any compilation that frees the flag ends
      in |0>_f (x) |phi> with a PURE marginal.  Hence source-exactness and a
      freeable flag are MUTUALLY EXCLUSIVE, with the quantitative ceiling
          sup_phi |<Psi_src| 0_f, phi>| = ||psi_{f=0}|| = cos(gamma/2) = 0.853
      over ALL clean-flag compilations (P2's 0.848 sits under it).  This
      closes the construction search: no gate sequence can do better.
  P7  downstream interference (part d): the LEAKED compilation tracks source
      statistics EXACTLY under a re-interference circuit on q; the
      mint-at-branch compile diverges loudly on the same circuit.
  P8  sub-shape scan over t2: the naive-strip residual sin^2(t2/2) vanishes
      only at t2 = 0 mod 2pi (Ry degenerates to +-identity — the already-
      accepted diagonal case).  No non-degenerate liftable sub-shape exists.
  P9  the t2 = pi corner: the conjugated strip DOES clean the flag (u = 0),
      yet fidelity vs source = cos^2(gamma/2) < 1 — the arm phase was applied
      to a basis eigenstate and lost.  A clean flag is NOT evidence of
      soundness (P6 already forbids it).
  P10 value arms (part c): with an X-on-p arm the conjugated strip cleans the
      flag exactly — but the result is STILL not source-exact: it coherently
      erases the record the source's icmp created.  A record-merging
      interference circuit separates them by 0.45 in P(q=0).  So the
      obstruction is arm-class-independent; the §3c-style decline before arm
      classification is correctly placed.

VERDICT (see MINT_AT_COMPARE.md): mint-at-compare fixes ARM SELECTION but no
flag-freeing compilation exists (P6).  The only exact compilation leaks the
entangled flag rail (P1, P7) — rejected as a silent default per the Rule 5
precedent (forward-only mode struck for silently degrading interference).
The conservative decline STANDS, hardened from a positional scan to an
SSA wire-walk (the sunk-compare layout evades the positional guard).

Run:  python3 investigation_mint_at_compare.py     (one-off; NOT in the build)
"""

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prototype_semantics import (  # noqa: E402
    H, RY, X, apply_cswap, bit, dist_qubit, op_1q, op_c1q, zero_state,
)

# Probe-3 constants (clearance_derived_base.py parity).
GAMMA, T2, A = 1.1, 0.8, 0.25
# Qubit layout (qubit 0 = MSB).  P replaces T for the value-arm probe P10.
Q, FLAG, T = 0, 1, 2
N = 3


def rz(th):
    """Project convention diag(1, e^{i th}) — the shipped runtime ABI."""
    return np.diag([1.0, np.exp(1j * th)]).astype(complex)


def mint(n=N):
    """flag ^= [basis(q) == 1] — the icmp_hl template (self-inverse: the same
    op is the icmp_inv strip)."""
    return op_c1q(X, Q, FLAG, n)


def source_state(gamma=GAMMA, t2=T2, a=A):
    """U_src — mint at the COMPARE (pre-Ry), then Ry, then the controlled
    phase arm on the minted flag.  The reference every probe compares to."""
    s = zero_state(N)
    s = op_1q(RY(gamma), Q, N) @ s
    s = mint() @ s                       # compare position: PRE-Ry basis
    s = op_1q(RY(t2), Q, N) @ s          # chained Ry
    s = op_c1q(rz(a), FLAG, Q, N) @ s    # the arm, on the SOURCE predicate
    return s


def leak_stream(gamma=GAMMA, t2=T2, a=A):
    """Candidate compilation: mint at the compare's wire window, swap-route
    the arm verbatim+uncontrolled, free the (clean) rail, NO strip, flag rail
    LEFT ALLOCATED.  Returns (state, rail |1>-pop)."""
    s = zero_state(N)
    s = op_1q(RY(gamma), Q, N) @ s
    s = mint() @ s                       # mint INSIDE the valid wire window
    s = op_1q(RY(t2), Q, N) @ s
    s = apply_cswap(s, FLAG, Q, T, N)    # route-in
    s = op_1q(rz(a), T, N) @ s           # arm body, verbatim, uncontrolled
    s = apply_cswap(s, FLAG, Q, T, N)    # route-back (adjoint of the split)
    return s, dist_qubit(s, T, N)[1]


def rho_q(s):
    """Reduced density matrix of q (trace out FLAG and T)."""
    r = np.zeros((2, 2), dtype=complex)
    for i in range(2 ** N):
        for j in range(2 ** N):
            if (i & ((1 << (N - 1)) - 1)) == (j & ((1 << (N - 1)) - 1)):
                r[bit(i, Q, N), bit(j, Q, N)] += s[i] * np.conj(s[j])
    return r


def fid(x, y):
    return abs(np.vdot(x, y))


def p1_leak_is_source_exact():
    src = source_state()
    got, rail = leak_stream()
    f = fid(src, got)
    print(f"  [P1 leak==source ] |<src|leak>| = {f:.12f}   rail |1>-pop = {rail:.3e}")
    assert abs(f - 1.0) < 1e-12, "mint-at-compare leak stream != source unitary"
    assert rail < 1e-12, "rail not |0> at free — hidden measurement"


def p2_mint_at_branch_diverges():
    # The un-guarded emitter stream: mint at the BRANCH (post-Ry), route, arm,
    # route-back, icmp_inv strip — clearance_derived_base.py probe 3 verbatim
    # (the source side carries the same trailing strip op for a stream-vs-
    # stream comparison; both orderings differ only in the mint position).
    s = zero_state(N)
    s = op_1q(RY(GAMMA), Q, N) @ s
    s = op_1q(RY(T2), Q, N) @ s
    s = mint() @ s                       # branch position: POST-Ry basis
    s = apply_cswap(s, FLAG, Q, T, N)
    s = op_1q(rz(A), T, N) @ s
    s = apply_cswap(s, FLAG, Q, T, N)
    s = mint() @ s                       # strip: post-Ry too -> CLEAN flag
    pf = dist_qubit(s, FLAG, N)[1]
    i = source_state()
    i = mint() @ i                       # source-side trailing strip (misses)
    f = fid(i, s)
    expect = np.cos(T2 / 2) ** 2
    print(f"  [P2 mint-at-branch] flag |1>-pop = {pf:.3e}   "
          f"|<src|emitted>| = {f:.6f}   (closed form cos^2(t2/2) = {expect:.6f})")
    assert pf < 1e-12, "expected a CLEAN flag — that is what makes it silent"
    assert abs(f - expect) < 1e-12, "probe-3 replication drifted"
    assert f < 0.99, "mint-at-branch failed to diverge — probe has no teeth"


def p3_naive_strip_misses():
    for label, with_arm in (("with phase arm", True), ("NO arm at all", False)):
        s, _ = leak_stream(a=A if with_arm else 0.0)
        s = mint() @ s                   # the 4.1 icmp_inv strip — post-Ry basis
        pf = dist_qubit(s, FLAG, N)[1]
        expect = np.sin(T2 / 2) ** 2
        print(f"  [P3 naive strip, {label:13s}] flag |1>-pop = {pf:.6f}   "
              f"(closed form sin^2(t2/2) = {expect:.6f})")
        assert abs(pf - expect) < 1e-12, "naive-strip residual drifted"
        assert pf > 0.1, "strip unexpectedly clean"


def conjugated_strip(s, t2):
    """Bennett-style flag uncompute: replay the intervening Ry backward,
    recompute/XOR the predicate, replay forward."""
    s = op_1q(RY(-t2), Q, N) @ s
    s = mint() @ s
    s = op_1q(RY(t2), Q, N) @ s
    return s


def p4_conjugated_strip_fails_phase_arms():
    for a in (A, 2.0):
        s, _ = leak_stream(a=a)
        s = conjugated_strip(s, T2)
        pf = dist_qubit(s, FLAG, N)[1]
        u2 = (np.cos(T2 / 2) * np.sin(T2 / 2)) ** 2 * 4 * np.sin(a / 2) ** 2
        expect = np.sin(GAMMA / 2) ** 2 * u2
        print(f"  [P4 conjugated strip, a={a:4.2f}] flag |1>-pop = {pf:.6f}   "
              f"(closed form b^2 sin^2(t2) sin^2(a/2) = {expect:.6f})")
        assert abs(pf - expect) < 1e-12, "conjugated-strip residual drifted"
        assert pf > 1e-4, "conjugated strip unexpectedly clean"


def p5_reverse_play_erases_the_arm():
    s, _ = leak_stream()
    s = op_c1q(rz(-A), FLAG, Q, N) @ s   # CRz† (flag still live — allowed)
    s = op_1q(RY(-T2), Q, N) @ s         # Ry†
    s = mint() @ s                       # strip: basis intact again -> exact
    pf = dist_qubit(s, FLAG, N)[1]
    s = op_1q(RY(T2), Q, N) @ s          # replay Ry
    s = op_c1q(rz(A), FLAG, Q, N) @ s    # replay arm: control is now |0> -> no-op
    f = fid(source_state(), s)
    expect = np.cos(GAMMA / 2) ** 2
    print(f"  [P5 reverse-play  ] flag |1>-pop = {pf:.3e}   |<src|final>| = "
          f"{f:.6f}   (closed form cos^2(gamma/2) = {expect:.6f})")
    assert pf < 1e-12, "reverse-play strip should be exact"
    assert abs(f - expect) < 1e-12, "arm-erasure fidelity drifted"


def p6_theorem_no_clean_flag_compilation():
    src = source_state()
    r = rho_q(src)
    purity = float(np.real(np.trace(r @ r)))
    a2, b2 = np.cos(GAMMA / 2) ** 2, np.sin(GAMMA / 2) ** 2
    u2 = (np.cos(T2 / 2) * np.sin(T2 / 2)) ** 2 * 4 * np.sin(A / 2) ** 2
    expect = 1 - 2 * a2 * b2 * (1 - u2)
    ceiling = np.cos(GAMMA / 2)
    # sup over phi of |<Psi_src|0_f,phi>| = norm of the f=0 component.
    psi0 = np.array([src[i] for i in range(2 ** N) if bit(i, FLAG, N) == 0])
    sup = float(np.linalg.norm(psi0))
    print(f"  [P6 theorem       ] purity(rho_q^src) = {purity:.6f}   "
          f"(closed form {expect:.6f});   clean-flag fidelity ceiling = "
          f"{sup:.6f} = cos(gamma/2) = {ceiling:.6f}")
    assert abs(purity - expect) < 1e-12, "purity closed form drifted"
    assert purity < 1 - 1e-3, "source marginal unexpectedly pure"
    assert abs(sup - ceiling) < 1e-12, "ceiling closed form drifted"
    assert sup < 1 - 1e-3, "no-clean-flag theorem has no teeth"


def p7_downstream_interference():
    # Re-interference circuit on q: Ry(-t2) (merge the branch record back into
    # the computational basis), then H, then P(q=0).  f is dead SSA — no
    # downstream op may touch it; predictions come from the joint state.
    def downstream(s):
        s = op_1q(RY(-T2), Q, N) @ s
        s = op_1q(H, Q, N) @ s
        return dist_qubit(s, Q, N)[0]

    p_src = downstream(source_state())
    leak, _ = leak_stream()
    p_leak = downstream(leak)
    # mint-at-branch artifact (P2 stream, flag stripped + freed).
    s = zero_state(N)
    s = op_1q(RY(GAMMA), Q, N) @ s
    s = op_1q(RY(T2), Q, N) @ s
    s = mint() @ s
    s = apply_cswap(s, FLAG, Q, T, N)
    s = op_1q(rz(A), T, N) @ s
    s = apply_cswap(s, FLAG, Q, T, N)
    s = mint() @ s
    p_branch = downstream(s)
    print(f"  [P7 interference  ] P(q=0): source = {p_src:.6f}   leaked = "
          f"{p_leak:.6f}   mint-at-branch = {p_branch:.6f}")
    assert abs(p_src - p_leak) < 1e-12, "leaked compile diverges downstream"
    assert abs(p_src - p_branch) > 1e-3, "branch-mint probe has no teeth"


def p8_subshape_scan():
    worst = []
    for t2 in np.linspace(0.0, 2 * np.pi, 49):
        s, _ = leak_stream(t2=t2)
        s = mint() @ s
        pf = dist_qubit(s, FLAG, N)[1]
        assert abs(pf - np.sin(t2 / 2) ** 2) < 1e-12
        if pf < 1e-12:
            worst.append(t2)
    print(f"  [P8 sub-shape scan] naive-strip residual sin^2(t2/2) over t2 in "
          f"[0,2pi]: zero only at t2 = {worst} (Ry = +-identity)")
    assert all(abs(t) < 1e-9 or abs(t - 2 * np.pi) < 1e-9 for t in worst), \
        "unexpected liftable sub-shape"


def p9_t2_pi_corner():
    s, _ = leak_stream(t2=np.pi)
    s = conjugated_strip(s, np.pi)
    pf = dist_qubit(s, FLAG, N)[1]
    f = fid(source_state(t2=np.pi), s)
    expect = np.cos(GAMMA / 2) ** 2
    print(f"  [P9 t2=pi corner  ] flag |1>-pop = {pf:.3e}   |<src|final>| = "
          f"{f:.6f}   (closed form cos^2(gamma/2) = {expect:.6f})")
    assert pf < 1e-12, "t2=pi conjugated strip should clean the flag"
    assert abs(f - expect) < 1e-12, "t2=pi corner fidelity drifted"
    assert f < 0.99, "clean flag must NOT imply soundness here"


def p10_value_arm_record_erasure():
    # Value arm on a NON-condition register p (layout reuses slot 2 as P):
    # c=(q>5); q=theta(q,t2); if(c){ p^=1 }.  Controlled-X stands in for the
    # routed arm (Demo A: route == controlled-op).
    P = T
    src = zero_state(N)
    src = op_1q(RY(GAMMA), Q, N) @ src
    src = mint() @ src
    src = op_1q(RY(T2), Q, N) @ src
    src = op_c1q(X, FLAG, P, N) @ src    # the value arm on the source predicate
    art = conjugated_strip(src.copy(), T2)
    pf = dist_qubit(art, FLAG, N)[1]

    # Record-merging interference: Ry(-t2) on q; CNOT(q->p) (uncompute p's
    # record against q's); H on q; P(q=0).
    def downstream(s):
        s = op_1q(RY(-T2), Q, N) @ s
        s = op_c1q(X, Q, P, N) @ s
        s = op_1q(H, Q, N) @ s
        return dist_qubit(s, Q, N)[0]

    p_src, p_art = downstream(src), downstream(art)
    expect_art = (1 + np.sin(GAMMA)) / 2
    print(f"  [P10 value arm    ] flag |1>-pop = {pf:.3e}   downstream P(q=0): "
          f"source = {p_src:.6f}   conjugated-strip artifact = {p_art:.6f}")
    assert pf < 1e-12, "value-arm conjugated strip should clean the flag"
    assert abs(p_src - 0.5) < 1e-12, "source record should kill q-coherence"
    assert abs(p_art - expect_art) < 1e-12, "artifact closed form drifted"
    assert abs(p_src - p_art) > 0.4, "record-erasure probe has no teeth"


if __name__ == "__main__":
    print("Design investigation: mint-at-compare (test_C_libtooling-ee5)")
    p1_leak_is_source_exact()
    p2_mint_at_branch_diverges()
    p3_naive_strip_misses()
    p4_conjugated_strip_fails_phase_arms()
    p5_reverse_play_erases_the_arm()
    p6_theorem_no_clean_flag_compilation()
    p7_downstream_interference()
    p8_subshape_scan()
    p9_t2_pi_corner()
    p10_value_arm_record_erasure()
    print("PASS: mint-at-compare fixes arm selection (P1) but NO flag-freeing\n"
          "      compilation is source-exact (P6 theorem; P3/P4/P5/P9/P10 close\n"
          "      every candidate strip); the only exact compilation LEAKS the\n"
          "      entangled flag rail (P1/P7).  Verdict: decline stands — see\n"
          "      MINT_AT_COMPARE.md.")
