/* slice_control_dicke_d42.c — bd test_C_libtooling-dm7f.77 (dm7f.51 step 2):
   the reporter's Dicke-state program (~/Desktop/alg_test/dicke/dicke.c,
   docs/CQ_FINDINGS.md F1), |D^4_2> by the Bärtschi–Eidenbenz split-and-cyclic-
   shift construction, written as plain C with no gate macros: every CNOT is
   `t ^= c`, every CRy `if (c) cq_theta(...)`, every CCRy an int compare.

   ACCEPTANCE (owner ruling owner-ruling-dicke-acceptance-folded-2026-10-14):
   the clang -O1 FOLDED circuit — the classical |0011> prep folds SCS_{4,2}'s
   first CRy away and turns its CCRy into a plain Ry — pinned as this golden,
   with an analytic D^4_2 check; no gate-count target.

   ANALYTIC CHECK (scratch tools of the dm7f.77 session: tracecheck.py propagates
   the exact amplitude vector through THIS golden's trace; ref.py runs the
   UNFOLDED textbook circuit of the source, gate for gate): both give
       (1/sqrt 6) * ( |0011> + |0101> + |0110> + |1001> + |1010> + |1100> )
   over (q1 q2 q3 q4), every amplitude +0.408248290464, every other basis state
   0, every cqrt_free on a |0> rail, and every leftover rail (the literal-2
   select operand, |0> scratch) in a fixed basis state — nothing entangled with
   the register file.
   bd dm7f.81 re-check (same propagator over the regenerated golden): the same
   six amplitudes, and NO leftover rail: `2*q4` is now one
   `cqrt_xorc_i32_controlled(flag, out, 2)` (the 0 arm emits nothing), replayed by
   the merge discharge; the two constant rails (64 qubits) are gone, so 4 qubits
   (the register file) are live at the end instead of 68.

   WHAT LOWERS IT (each a general mechanism with its own lit fixtures):
   SCS_{3,2}'s CRy is a branch on q2 rotating q2 itself; the program's own
   `q4 = !q2` is substituted as the guard (design D4 case 2,
   control_regcond_negated_guard_accept.ll). Its CCRy reads the merge of that
   region through a compare (condProvCoveredPhiGates) and a 4.4 select whose
   condition `q3` is read as a register root (control_cmp_merge_phi_covered_
   accept.ll). SCS_{2,1}: -O1's `icmp ne i8 (q1 phi), (zext q2)` is narrowed to
   an i1 xor (design D1) and committed as a REGISTER CONDITION on q2 (design D3,
   control_regcond_boolstorage_scs21_accept.ll); `q3 ^= q1` and `q2 ^= q1` lower
   in place (cqrt_cnot), the measured `q4 = !q2` record counting as settled
   (design D2(b)); every angle cone is hoisted out of its arm.

   The trace-only runtime measures 0, so the program prints 0000. */
#include <stdio.h>
#include <math.h>

int main(void) {
    bool q1 = 0, q2 = 0, q3 = 1, q4 = 1;
    int s;

    /* SCS_{4,2} */
    q4 ^= q3;
    if (q4) cq_theta(&q3, 2.0 * acos(sqrt(1.0 / 4)));
    q4 ^= q3;
    q4 ^= q2;
    s = 2 * q4 + q3;
    if (s == 3) cq_theta(&q2, 2.0 * acos(sqrt(2.0 / 4)));
    q4 ^= q2;

    /* SCS_{3,2} */
    q3 ^= q2;
    if (q3) cq_theta(&q2, 2.0 * acos(sqrt(1.0 / 3)));
    q3 ^= q2;
    q3 ^= q1;
    s = 2 * q3 + q2;
    if (s == 3) cq_theta(&q1, 2.0 * acos(sqrt(2.0 / 3)));
    q3 ^= q1;

    /* SCS_{2,1} */
    q2 ^= q1;
    if (q2) cq_theta(&q1, 2.0 * acos(sqrt(1.0 / 2)));
    q2 ^= q1;

    printf("%d%d%d%d\n", cq_measure(q1), cq_measure(q2), cq_measure(q3), cq_measure(q4));
    return 0;
}
