#!/usr/bin/env python3
"""
*** DESIGN ARTIFACT — NOT A TEST, NOT A GATE, NEVER WIRED INTO ctest. ***

Same category as the one-off oracles in `docs/design/rssa-swap-control/`
(`prototype_semantics.py`, `clearance_derived_base.py`,
`investigation_mint_at_compare.py`): a throwaway numeric check of a DESIGN
PREMISE, run by hand while reasoning, kept so the reasoning is reproducible.

READ THIS BEFORE QUOTING ANY NUMBER BELOW
=========================================
Rule 2 and the owner decision of 2026-06-10 put SIMULATION OUT OF SCOPE as a
correctness gate for this project: correctness is established by analytic/trace
reasoning, golden end-to-end diffs, and independent adversarial review. CQ has no
simulator and is not getting one. So this file:

  * MUST NOT be added to `tests/`, to `CMakeLists.txt`, or to any ctest entry;
  * MUST NOT be cited as evidence that a lowering is correct;
  * MAY be cited as what it is — a numeric illustration of the standard
    record/decoherence argument on a 1-qubit toy, which is the PREMISE the
    record-family plan rests on (bd test_C_libtooling-6uqc / -nepx, "Risk 1").

WHAT IT COMPUTES
================
Section A — the premise itself.
  (i)  Ry(b) . Ry(a) |0>                        — no record
  (ii) the same with a CNOT copy of the wire onto a fresh |0> ancilla taken
       BETWEEN the two rotations; the ancilla is traced out.
  If the record is a basis record of the wire, the reduced state of the wire is
  DIAGONAL in that basis between the rotations, so the second rotation cannot
  interfere amplitudes across it and P(0) collapses to the classical mixture.
  Closed form of the gap: P_free(0) - P_rec(0) = -(1/2) sin(a) sin(b).

Section B — the shipped artifact bd nepx is about.
  `tests/e2e/slice_control_seq_grover.expected.log` runs
      alloc; ry(h0, 0.5); h1 = add_hl(h0, 3); ... ; h4 = sub_hl(h1, 3);
      ry(h4, -0.5)
  The out-of-place `_hl` templates KEEP h0 and h1 alive, so at the S-dagger
  `ry(h4, -0.5)` the state is sum_a c_a |a>_h0 |a+3>_h1 |a>_h4. Section B models
  that at one qubit: Ry(t) — record — Ry(-t), and compares it against the M-C
  lowering (`cqrt_addc_<W>` in place: no ancestor rail is ever minted), which is
  Ry(t) — Ry(-t) with nothing recorded.
  The M-C version returns the wire EXACTLY to |0>. The shipped one does not.

  NOTE ON THE MODEL, so it is not overclaimed: an out-of-place `add_hl(q, 3)`
  is not literally a CNOT — it is |a> |0> -> |a> |a+3>, a permutation that writes
  a one-to-one FUNCTION of the wire's basis label onto a fresh rail. For
  dephasing purposes those are the same object (any injective basis-label copy
  makes the reduced state diagonal); CNOT is the 1-qubit instance. Section B
  prints the d-level version too (d = 4, record = |a> -> |a+3 mod 4|), so the
  claim does not rest on the qubit special case.

RUN
===
    python3 tools/record_census/design_artifact_record_dephasing.py
"""

import math
import sys

import numpy as np

I2 = np.eye(2, dtype=complex)


def ry(t):
    c, s = math.cos(t / 2), math.sin(t / 2)
    return np.array([[c, -s], [s, c]], dtype=complex)


def kron(*ms):
    out = np.array([[1.0 + 0j]])
    for m in ms:
        out = np.kron(out, m)
    return out


CNOT = np.array([[1, 0, 0, 0],
                 [0, 1, 0, 0],
                 [0, 0, 0, 1],
                 [0, 0, 1, 0]], dtype=complex)   # control q0, target q1


def reduced_q0(psi):
    """Partial trace over qubit 1 of a 2-qubit state vector."""
    m = psi.reshape(2, 2)
    return m @ m.conj().T


def section_a(a, b):
    print(f"SECTION A — the premise, a = {a:.6f} rad, b = {b:.6f} rad")
    # (i) no record
    psi = ry(b) @ ry(a) @ np.array([1, 0], dtype=complex)
    p0_free = abs(psi[0]) ** 2
    # (ii) CNOT record between the rotations, ancilla traced out
    psi2 = kron(ry(a), I2) @ np.array([1, 0, 0, 0], dtype=complex)
    psi2 = CNOT @ psi2
    psi2 = kron(ry(b), I2) @ psi2
    rho = reduced_q0(psi2)
    p0_rec = rho[0, 0].real
    gap_closed_form = -0.5 * math.sin(a) * math.sin(b)
    purity = np.trace(rho @ rho).real
    print(f"  (i)  no record        P(0) = {p0_free:.12f}"
          f"   [= cos^2((a+b)/2)]")
    print(f"  (ii) CNOT record      P(0) = {p0_rec:.12f}"
          f"   [= cos^2(a/2)cos^2(b/2) + sin^2(a/2)sin^2(b/2)"
          f" = the classical mixture]")
    print(f"       reduced-state purity Tr(rho^2) = {purity:.12f}"
          f"   (1 = pure, 0.5 = maximally mixed)")
    print(f"  interference term     diff = {p0_free - p0_rec:+.12f}"
          f"   closed form -sin(a)sin(b)/2 = {gap_closed_form:+.12f}")
    # the classical mixture, computed a THIRD way, as a cross-check
    ca, sa = math.cos(a / 2), math.sin(a / 2)
    mix = ca * ca * math.cos(b / 2) ** 2 + sa * sa * math.sin(b / 2) ** 2
    print(f"  cross-check: mixture computed directly = {mix:.12f}"
          f"  (agrees: {abs(mix - p0_rec) < 1e-12})")
    print()


def section_b(t=0.5):
    print(f"SECTION B — the slice_control_seq_grover shape, theta = {t} rad")
    ket0 = np.array([1, 0], dtype=complex)
    # M-C lowering: in-place addc, NO ancestor rail is minted.
    psi = ry(-t) @ ry(t) @ ket0
    print(f"  M-C (in place, no record)   P(|0>) = {abs(psi[0])**2:.12f}"
          f"   <- S-dagger returns the wire EXACTLY to |0>")
    # Shipped lowering: the out-of-place `_hl` template mints a live ancestor.
    psi2 = CNOT @ (kron(ry(t), I2) @ np.array([1, 0, 0, 0], dtype=complex))
    psi2 = kron(ry(-t), I2) @ psi2
    rho = reduced_q0(psi2)
    print(f"  shipped (record kept)       P(|0>) = {rho[0,0].real:.12f}"
          f"   [= cos^4(t/2) + sin^4(t/2)]")
    print(f"                              purity = "
          f"{np.trace(rho @ rho).real:.12f}")
    c, s = math.cos(t / 2), math.sin(t / 2)
    print(f"  cross-check closed form            = {c**4 + s**4:.12f}")

    # d-level version: the record is |a> -> |a+3 mod d>, i.e. the real
    # `cq_template_add_i32_hl(h0, 3)`, not a CNOT.
    d = 4
    theta = t
    # A "rotation" that genuinely interferes across the d basis labels: use the
    # real orthogonal generator exp(-i*theta*G/2) with G the (real) hopping
    # generator, so the toy has the SAME structure (a unitary that mixes basis
    # labels) without pretending to be Ry.
    G = np.zeros((d, d), dtype=complex)
    for k in range(d - 1):
        G[k, k + 1] = -1j
        G[k + 1, k] = 1j
    U = _expm_herm(-0.5 * theta * G)
    Ud = _expm_herm(+0.5 * theta * G)
    v0 = np.zeros(d, dtype=complex)
    v0[0] = 1.0
    free = Ud @ (U @ v0)
    print(f"  d={d} register, no record   P(|0>) = {abs(free[0])**2:.12f}")
    # with the +3 mod d record on a fresh d-level rail
    psi_d = np.zeros((d, d), dtype=complex)
    after = U @ v0
    for a_ in range(d):
        psi_d[a_, (a_ + 3) % d] = after[a_]
    psi_d = Ud @ psi_d                      # act on the wire index only
    rho_d = psi_d @ psi_d.conj().T
    print(f"  d={d} register, +3 record   P(|0>) = {rho_d[0,0].real:.12f}"
          f"   purity = {np.trace(rho_d @ rho_d).real:.12f}")
    print()


def _expm_herm(A):
    """exp(A) for A = -i*H with H Hermitian, via eigendecomposition."""
    H = 1j * A
    w, V = np.linalg.eigh(H)
    return V @ np.diag(np.exp(-1j * w)) @ V.conj().T


def main():
    print(__doc__.split("RUN")[0].strip())
    print("=" * 74)
    for a, b in ((math.pi / 2, math.pi / 2), (0.5, -0.5), (0.5, 0.25)):
        section_a(a, b)
    section_b(0.5)
    print("CONCLUSION (the premise, restated in one line): a live basis record of"
          "\nthe wire makes the wire's reduced state diagonal, so the NEXT"
          "\nnon-diagonal gate cannot interfere across it. That is why bd nepx"
          "\ncalls the shipped seq-grover golden a DEPHASED circuit, and why M-C"
          "\n(never minting the ancestor) is the fix rather than a peephole.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
