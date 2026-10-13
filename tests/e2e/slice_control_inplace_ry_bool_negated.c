/* slice_control_inplace_ry_bool_negated.c — ANTI-CONTROL BY Ry ADDITIVITY, the
   one genuine design decision of bd `test_C_libtooling-l4x4` sub-increment
   l4x4.b (SCOPE §2.3 option A).

       if (!b) { cq_theta(&r, 0.9); }

   `clang -O1` gives this an ORIENTATION-B diamond (`br i1 %b, merge, arm`), so
   the arm is the FALSE successor and it is plain-C reachable.

   THE COMPARE FORM SPENDS A `cqrt_x(flag)` BRACKET HERE — see
   `slice_control_inplace_ry_negated.expected.log`, lines 6 and 8 — AND THIS FORM
   MAY NOT. bd `3qlq.4`'s invariant is "never a `cqrt_x` on a user register,
   EVER" (`Uncomputation::preservesBorrowedParent` admits an uncontrolled
   `cqrt_rz_` on a borrowed parent BY NAME and fails CLOSED on anything else, so
   a bracket would freeze every chain that borrows the register), and unlike the
   PHASE path there is no identity to fall back on: `X·P(θ)·X = e^{iθ}·P(−θ)` is
   a statement about a DIAGONAL gate, and `Ry` is not one.

   SO THE ARM IS FIRED UNCONDITIONALLY AND CANCELLED UNDER THE FLAG:

       cqrt_ry_i32(h1, θ)                   b = 0 → Ry(θ)
       cqrt_ry_i32_controlled(h0, h1, −θ)   b = 1 → Ry(θ)·Ry(−θ) = I

   which is the source's unitary on BOTH branches. `−θ` is an IEEE SIGN FLIP, not
   an `fsub`: no rounding fence has a subject here (the retired Inc-2b
   by-difference angle select's 2^-40 bound did). It is width-safe
   because `cqrt_ry_<W>` is TENSORED — each of the W qubits independently sees
   `Ry(θ)Ry(−θ) = I`.

   THE WITNESS IS A REAL `compare_files` GATE, `e2e-inplace-ry-bool-negated-twin-identical`:
   this slice's trace must be BYTE-IDENTICAL to
   `slice_control_inplace_ry_bool_negated_twin.c`, which is the by-hand spelling
   of the same circuit (`cq_theta(&r, 0.9); if (b) cq_theta(&r, -0.9);`).

   ⚠ IT IS AN INTERNAL-CONSISTENCY GATE, NOT AN ORACLE GATE, and the label
   matters: BOTH halves lower on the l4x4.b binary and BOTH decline on `main`
   0c7380c (`bare i1 register condition`). What it proves is that the compiler's
   negation and the programmer's hand-written cancellation are the same gate
   stream — not that an older compiler agreed. */
int slice(void) {
    _Bool b = 0;
    int   r = 7;
    cq_theta(&b, 0.5);
    cq_theta(&r, 0.25);
    if (!b) {                      /* orientation-B: the arm is the FALSE edge */
        cq_theta(&r, 0.9);
    }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
