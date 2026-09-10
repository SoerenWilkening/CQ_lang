/* slice_control_select_bool.c — bd test_C_libtooling-r9e5 (Inc 1b-B.1):
   THE 4.4 DATA SELECT ON A BARE `_Bool` CONDITION, and this is the OWNER'S OWN
   `main()` verbatim (`example/grover/grover_oracle_uncompute.c` as it stood at
   the close of 2026-09-10 — the file the 3qlq.4 HANDOFF recorded as still
   declining `bare i1 register condition` on `main` b00fdc2 / 87d0699).

   SOURCE INTENT, as typed:
       int a = 5; bool b0 = 0; bool b1 = 0;
       if (a >= 3) b0 = cq_theta(b0, 0.5);   // classical guard: always taken
       if (b0 == 1) a -= 3;                  // a becomes 2 or 5 with b0
       return cq_measure(b0) + cq_measure(a);

   WHAT clang -O1 HANDS THE PASS (Rule 9 — the trace will not match what you
   typed): `a` is the constant 5 so the guard folds away, `b1` is dead, and
   `if (b0 == 1) a -= 3;` becomes `select i1 %b0, i32 2, i32 5` — the register
   ITSELF as the select's condition, with no compare anywhere in the module.
   That is the DATA half of the bare-bool condition; the PHASE half shipped as
   `slice_control_phase_bool_diamond.c` in Inc 1b.

   EXPECTED TRACE (measured, the golden). The §5a controlled-XOR copy merge,
   instruction for instruction, with ONE change: the flag is a CNOT COPY of the
   register instead of a compare mint.
       alloc_i1(0) -> h0 ; ry_i1(h0, 0.5)      the `_Bool` register
       alloc_i1(0) -> h1 ; cnot(h0, h1)        the copy flag  (Σ α_x |x⟩|x⟩)
       alloc_i32(0) -> h2                      the |0> out rail
       alloc_i32(2) -> h3 ; copy_i32_controlled(h1, h3, h2)     fires on b0 = 1
       x(h1) ; alloc_i32(5) -> h4 ; copy_i32_controlled(h1, h4, h2) ; x(h1)
       cnot(h0, h1) ; free(h1)                 h1 back to |0>, a proven-|0> free
       measure_i1(h0) ; measure_i32(h2)
   NO `cqrt_x` ON THE REGISTER, EVER — that is why the flag is copied out rather
   than the register bracketed in place (bd memory
   [diagonal-only-on-user-registers-3qlq4]; the phase path's escape, the diagonal
   identity X·P(θ)·X = e^{iθ}·P(−θ), has no analogue for a controlled basis
   COPY). EXACTLY ONE free (the copy flag): the register, %out and the two
   materialized sources are LEFT ALLOCATED, because each is entangled with %out
   through the copy and freeing one would be a hidden measurement (Rules 6/8).

   THE TWIN WITNESS is `slice_control_select_bool_int_twin.c` — the same program
   with `int b0` — which compiled BEFORE this increment through the ordinary
   compare mint. THE REDUCTION, measured (15 lines here, 14 there): this file's
   THREE flag lines `alloc_i1(0) -> h1`, `cnot(h0, h1)` … `cnot(h0, h1)` become
   the twin's TWO, `cq_template_icmp_eq_i32_hl(h0, 1) -> h1` and its `_unc`
   strip; and `i1` becomes `i32` on the register's alloc/ry/measure. Everything
   between — the |0> out rail, both materialized sources, both controlled
   copies, both `cqrt_x`, the single `cqrt_free` — is line-for-line the same.
   Reduction STATED, not mechanized: a `compare_files` gate would assert
   something false (the Inc-4 state-prep precedent).
   STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;

    if (a >= 3) {
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    return cq_measure(b0) + cq_measure(a);
}
