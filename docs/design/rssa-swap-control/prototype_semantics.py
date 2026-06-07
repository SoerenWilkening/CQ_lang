#!/usr/bin/env python3
"""
RSSA swap-routed tainted control flow -- semantics prototype.

This is a PRINCIPLE prototype, not the production lowering. It uses a tiny exact
statevector simulator to validate the semantics of the proposed model BEFORE we
commit any of it to the LLVM pass framework. Registers are modelled as single
qubits for clarity; the arguments generalise to multi-qubit registers verbatim
(cqrt_cswap already swaps whole register handles).

It demonstrates three claims:

  DEMO A  -- a tainted two-arm `if` lowered as
                 br   -> cqrt_cswap routing operands into per-arm work registers
                 body -> UNCONTROLLED gates on the routed registers
                 phi  -> cqrt_cswap routing the active result back
             reproduces the measurement statistics of the current controlled-op
             lowering, bit for bit.

  DEMO B  -- the coherence boundary. The swap-route model leaves the inactive
             arm's work register entangled with the control. If the region's
             output is only MEASURED (the v1 scope), this is invisible. If the
             output is INTERFERED (Grover/Hadamard-test territory -- explicitly
             out of v1 scope), it dephases the result. We quantify the gap, and
             show that adding the Bennett uncompute step closes it.

  DEMO C  -- multiple tainted `return`s via one return register PER return site
             plus a priority cascade at the exit. Validates the intuition that
             each controlled swap routes the live data away so the "remaining
             work" runs uncontrolled, with program-order semantics restored by
             the exit cascade. No per-site "not-yet-returned" flag needed.

Run:  python3 prototype_semantics.py
"""

import numpy as np

# ---------------------------------------------------------------------------
# Tiny exact statevector simulator (qubit 0 = most significant bit).
# ---------------------------------------------------------------------------
I2 = np.eye(2, dtype=complex)
X = np.array([[0, 1], [1, 0]], dtype=complex)
H = np.array([[1, 1], [1, -1]], dtype=complex) / np.sqrt(2)
P0 = np.array([[1, 0], [0, 0]], dtype=complex)
P1 = np.array([[0, 0], [0, 1]], dtype=complex)


def RY(theta):
    c, s = np.cos(theta / 2), np.sin(theta / 2)
    return np.array([[c, -s], [s, c]], dtype=complex)


def kronlist(ops):
    out = ops[0]
    for o in ops[1:]:
        out = np.kron(out, o)
    return out


def zero_state(n):
    v = np.zeros(2 ** n, dtype=complex)
    v[0] = 1.0
    return v


def op_1q(gate, q, n):
    return kronlist([gate if k == q else I2 for k in range(n)])


def op_c1q(gate, ctrl, tgt, n):
    """Controlled-`gate` (control on |1>)."""
    a = kronlist([P0 if k == ctrl else I2 for k in range(n)])
    b = kronlist([P1 if k == ctrl else (gate if k == tgt else I2) for k in range(n)])
    return a + b


def bit(i, q, n):
    return (i >> (n - 1 - q)) & 1


def cswap_perm(ctrl, a, b, n):
    perm = np.arange(2 ** n)
    for i in range(2 ** n):
        if bit(i, ctrl, n):
            if bit(i, a, n) != bit(i, b, n):
                perm[i] = i ^ (1 << (n - 1 - a)) ^ (1 << (n - 1 - b))
    return perm


def apply_cswap(state, ctrl, a, b, n):
    """Fredkin: swap registers a,b iff ctrl == 1.  (cqrt_cswap)"""
    return state[cswap_perm(ctrl, a, b, n)]


def prob_qubit(state, q, val, n):
    p = 0.0
    for i in range(2 ** n):
        if bit(i, q, n) == val:
            p += abs(state[i]) ** 2
    return p


def dist_qubit(state, q, n):
    return np.array([prob_qubit(state, q, 0, n), prob_qubit(state, q, 1, n)])


# ===========================================================================
# DEMO A -- swap-route reproduces controlled-op measurement statistics.
#   Region:  x = c ? RY(alpha)(x0) : RY(beta)(x0)   ; then measure x.
# ===========================================================================
def demo_A():
    print("=" * 72)
    print("DEMO A  tainted two-arm if: swap-route vs controlled-op (measured x)")
    print("=" * 72)
    alpha, beta = 0.7, 2.3
    gamma = 1.1          # control prepared in a non-trivial superposition
    phi0 = 0.9           # x0 = RY(phi0)|0>

    # --- reference: current controlled-op lowering (coherence-clean, in place)
    n = 2  # x=0, c=1
    s = zero_state(n)
    s = op_1q(RY(phi0), 0, n) @ s           # x0
    s = op_1q(RY(gamma), 1, n) @ s          # c superposition
    s = op_c1q(RY(alpha), 1, 0, n) @ s      # if c:   RY(alpha) on x
    s = op_1q(X, 1, n) @ s                  # bracket: control on ~c
    s = op_c1q(RY(beta), 1, 0, n) @ s       # else:   RY(beta) on x
    s = op_1q(X, 1, n) @ s
    ref = dist_qubit(s, 0, n)

    # --- proposed: swap-route with UNCONTROLLED arm bodies
    n = 4  # x=0, c=1, T=2 (then reg), E=3 (else reg); T,E start |0>
    s = zero_state(n)
    s = op_1q(RY(phi0), 0, n) @ s
    s = op_1q(RY(gamma), 1, n) @ s
    # br: route x0 into the active arm's register (T if c, E if ~c)
    s = apply_cswap(s, 1, 0, 2, n)                      # cswap(c;  x, T)
    s = op_1q(X, 1, n) @ s
    s = apply_cswap(s, 1, 0, 3, n)                      # cswap(~c; x, E)
    s = op_1q(X, 1, n) @ s
    # arm bodies: UNCONTROLLED gates, copied verbatim from the source
    s = op_1q(RY(alpha), 2, n) @ s                      # then body on T
    s = op_1q(RY(beta), 3, n) @ s                       # else body on E
    # phi: route the active result back into x
    s = apply_cswap(s, 1, 0, 2, n)                      # cswap(c;  x, T)
    s = op_1q(X, 1, n) @ s
    s = apply_cswap(s, 1, 0, 3, n)                      # cswap(~c; x, E)
    s = op_1q(X, 1, n) @ s
    got = dist_qubit(s, 0, n)

    print(f"  measured x  reference (controlled-op): P0={ref[0]:.6f} P1={ref[1]:.6f}")
    print(f"  measured x  swap-route   (proposed)  : P0={got[0]:.6f} P1={got[1]:.6f}")
    err = float(np.max(np.abs(ref - got)))
    print(f"  max |diff| = {err:.2e}")
    assert err < 1e-12, "swap-route did NOT reproduce controlled-op statistics"
    print("  PASS: swap-route reproduces controlled-op measurement statistics.\n")


# ===========================================================================
# DEMO B -- coherence boundary (Hadamard test on the control).
#   Region: if (c) RY(theta)(x).  c starts |+>, x starts |0>.
#   Then H on c, measure c.  P(c=0) encodes interference; entangled garbage
#   reduces the visibility.
# ===========================================================================
def demo_B():
    print("=" * 72)
    print("DEMO B  coherence boundary: Hadamard test, P(c=0) after re-interfering")
    print("=" * 72)
    theta = np.pi / 2
    clean_expected = (1 + np.cos(theta / 2)) / 2

    # --- clean controlled-op
    n = 2  # x=0, c=1
    s = zero_state(n)
    s = op_1q(H, 1, n) @ s
    s = op_c1q(RY(theta), 1, 0, n) @ s
    s = op_1q(H, 1, n) @ s
    p_clean = prob_qubit(s, 1, 0, n)

    # --- swap-route, garbage IGNORED (v1 default)
    n = 3  # x=0, c=1, a=2 (work reg)
    s = zero_state(n)
    s = op_1q(H, 1, n) @ s
    s = apply_cswap(s, 1, 0, 2, n)        # cswap(c; x, a)
    s = op_1q(RY(theta), 2, n) @ s        # UNCONTROLLED body on work reg
    s = apply_cswap(s, 1, 0, 2, n)        # cswap(c; x, a)  (merge back)
    s = op_1q(H, 1, n) @ s
    p_ignore = prob_qubit(s, 1, 0, n)

    # --- swap-route + Bennett uncompute (the "later" coherent path)
    n = 3
    s = zero_state(n)
    s = op_1q(H, 1, n) @ s
    s = apply_cswap(s, 1, 0, 2, n)
    s = op_1q(RY(theta), 2, n) @ s
    s = apply_cswap(s, 1, 0, 2, n)
    # uncompute the garbage left in `a` on the c=0 branch: RY(-theta) on a if ~c
    s = op_1q(X, 1, n) @ s
    s = op_c1q(RY(-theta), 1, 2, n) @ s
    s = op_1q(X, 1, n) @ s
    s = op_1q(H, 1, n) @ s
    p_uncomp = prob_qubit(s, 1, 0, n)

    print(f"  P(c=0)  clean controlled-op           : {p_clean:.6f}   (analytic {clean_expected:.6f})")
    print(f"  P(c=0)  swap-route, garbage IGNORED    : {p_ignore:.6f}   <-- dephased")
    print(f"  P(c=0)  swap-route + Bennett uncompute : {p_uncomp:.6f}   <-- restored")
    print(f"  interference lost by ignoring garbage  : {p_clean - p_ignore:.6f}")
    assert abs(p_clean - clean_expected) < 1e-12
    assert abs(p_uncomp - p_clean) < 1e-12, "uncompute did not restore coherence"
    assert p_clean - p_ignore > 1e-3, "expected measurable dephasing"
    print("  TAKEAWAY: under MEASURE-only use these are indistinguishable;")
    print("            under RE-INTERFERENCE they are not -> v1 must reject/scope")
    print("            coherent use, uncompute is the documented later extension.\n")


# ===========================================================================
# DEMO C -- multiple tainted returns: per-site return registers + priority
#   cascade.  Program:
#       (work A)                 # value v_A = L0
#       if (c1) return L;        # site 1, value at this point = L0
#       L = X(L)   (work B)
#       if (c2) return L;        # site 2, value at this point = X(L0)
#       L = X(L)   (work C)
#       return L;                # fall-through, value = X(X(L0)) = L0
#   Expected (program order): c1 ? L0 : (c2 ? 1-L0 : L0)
# ===========================================================================
def demo_C():
    print("=" * 72)
    print("DEMO C  multiple tainted returns: per-site regs + exit priority cascade")
    print("=" * 72)
    n = 5  # L=0, c1=1, c2=2, R1=3, R2=4
    header = "  L0 c1 c2 | expected  got   ok"
    print(header)
    all_ok = True
    for L0 in (0, 1):
        for c1 in (0, 1):
            for c2 in (0, 1):
                s = zero_state(n)
                if L0: s = op_1q(X, 0, n) @ s
                if c1: s = op_1q(X, 1, n) @ s
                if c2: s = op_1q(X, 2, n) @ s
                # site 1: park live -> R1 controlled on c1
                s = apply_cswap(s, 1, 0, 3, n)
                # work B
                s = op_1q(X, 0, n) @ s
                # site 2: park live -> R2 controlled on c2
                s = apply_cswap(s, 2, 0, 4, n)
                # work C
                s = op_1q(X, 0, n) @ s
                # exit priority cascade: lower priority first, c1 (highest) LAST
                s = apply_cswap(s, 2, 0, 4, n)   # if c2: result <- R2
                s = apply_cswap(s, 1, 0, 3, n)   # if c1: result <- R1 (wins)
                # measure L (basis input -> deterministic)
                pL = dist_qubit(s, 0, n)
                got = int(pL[1] > 0.5)
                assert abs(max(pL) - 1.0) < 1e-12, "result not deterministic"
                expected = L0 if c1 else ((1 - L0) if c2 else L0)
                ok = (got == expected)
                all_ok &= ok
                print(f"  {L0}  {c1}  {c2} |    {expected}      {got}    {'ok' if ok else 'FAIL'}")
    assert all_ok, "multiple-return priority semantics violated"
    print("  PASS: per-site registers + priority cascade = program-order returns.")
    print("        Each swap routes live data away; remaining work stays")
    print("        uncontrolled; the cascade restores first-return-wins.\n")


if __name__ == "__main__":
    demo_A()
    demo_B()
    demo_C()
    print("All demos passed.")
