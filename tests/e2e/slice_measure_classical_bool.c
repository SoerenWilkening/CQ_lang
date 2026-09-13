/* slice_measure_classical_bool.c — bd test_C_libtooling-21mg: THE OWNER'S FILE.
   `cq_measure` of a value that never became quantum lowers to the classical
   value — no gate, no rail, no trace line.

   THE SOURCE IS THE OWNER'S 2026-09-11 22:18 EDIT of
   `example/grover/grover_oracle_uncompute.c` with the second region commented
   out (`//if (a >= 3){ // b1 = cq_theta(b1, 0.5); //}`), which leaves `b1`
   declared, never assigned, and measured. On `main` e96f89c / 86c0d25 that one
   classical measure refused the WHOLE program:

       cq_measure_<sfx> operand not recognized; expected a tainted i32 handle

   — an over-decline under the 2026-09-11 expressiveness ruling ("our end-goal is
   to not decline any code that will lead to a valid quantum circuit"), since
   measuring a classical bit IS a valid, if trivial, circuit: the measurement is
   the identity on the quantum state and its outcome is the bit.

   WHAT THE GOLDEN WITNESSES, and it is the whole point: the trace is BYTE
   IDENTICAL to `slice_measure_classical_bool_twin.c`'s — the same program with
   `cq_measure(b1)` DELETED — pinned by the `compare_files` gate
   `e2e-measure-classical-bool-twin-identical`. The classical measure is worth
   exactly ZERO gates, not "about zero": a rail minted for `b1` (the f64/angle
   miscompile family — allocating for classical data), or a stray
   `cqrt_measure_i1` on a fresh |0> rail, would both still be a self-consistent,
   verify-clean, stage-2b-clean trace. Only the twin diff can see it. This is the
   ONLY layer that LINKS, so it is also what proves no new runtime symbol was
   needed (Rule 2).

   THE STREAM (15 lines, and every line is the b0 half): `clang -O1` const-folds
   `a >= 3`, so the rotation on `b0` is unconditional, and folds `if (b0 == 1) a
   -= 3` into ONE `select i1 %b0, i32 2, i32 5` — the 4.4 tainted-condition data
   select on a BARE `_Bool` RAIL condition (bd 3qlq.4 / l4x4.b). The rail root
   gets the CNOT-copy ancilla, NOT an `x` bracket on the user register: alloc+ry
   on `b0`; alloc the ancilla + `cqrt_cnot(b0, bf)`; alloc the |0> out rail; two
   X-bracketed `cqrt_copy_i32_controlled` of the materialized 2 and 5; the CNOT
   back (x ^ x = 0 on every branch, which is what makes the ONE `cqrt_free` a
   proven-|0> one); then `cqrt_measure_i1(b0)` and `cqrt_measure_i32(out)`.
   STRICT stage 2b: 5 rail mints, 4 left allocated, 1 free verified, 0 violations,
   0 unproven. `b0` is read only as a CONTROL and measured once — never
   bracketed, never freed (Rule 6: Ry(0.5)|0> != |0>).

   lit twin: `control_measure_classical_bool_owner.ll` (this file's `-O1` main).

   The owner's `main` returns the sum of the three measurements; the harness runs
   the binary under `set -euo pipefail`, so the body is moved into `slice()` and
   `main` returns 0 — the house convention for every slice in this directory. */
#include "CQ.h"

int slice(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    if (a >= 3) {
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}

int main(void) {
    (void) slice();
    return 0;
}
