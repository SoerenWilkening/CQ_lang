/* slice_undef_seed_uncontrolled.c — bd z9t1 customer C2a: an UNINITIALIZED
   `_Bool` prepared UNCONDITIONALLY.

   OWNER RULING 2026-09-14, verbatim: "we should NOT make every uninitialized
   variable to 0. Jut before it hits cq_alloc_*. then clang still can exploid
   it" / "both codes are supposed to compie!! also no warnings."

   WHAT THIS SLICE WITNESSES, and it is the half no lit fixture can. On the
   2026-09-13 oracle this program already compiled — SILENTLY — and handed
   `i1 undef` to `cqrt_alloc_i1`, so the starting basis state of the rail was
   whatever the `-O0` stage-3 link materialised. The golden the oracle produced
   for it opened with

       cqrt_alloc_i1(1) -> h0

   — a `1` the program never wrote, and a value the golden byte-diff would then
   have pinned as if it were the program's meaning (Rule 2: the trace proves
   every symbol resolves, never that the unitary is right). The golden beside
   this file opens with `cqrt_alloc_i1(0) -> h0`. THAT LINE IS THE WHOLE POINT:
   the rail is now deterministically |0>, and the e2e layer is the only one that
   can show the materialised VALUE rather than the IR that produced it.

   The rest of the stream is the ordinary bare-`_Bool` rail-condition data select
   (bd 3qlq.4 / l4x4.b): `if (b) a -= 3` is folded by `clang -O1` into one
   `select i1 %b, i32 2, i32 5`, whose rail ROOT gets the CNOT-copy ancilla
   rather than an `x` bracket on the user register — `x ^ x = 0` on every branch
   is what makes the single `cqrt_free` a proven-|0> one (Rule 6). `b` itself is
   read only as a CONTROL and measured once: never bracketed, never freed,
   because `Ry(0.5)|0> != |0>`.

   NO WARNING, BY RULING. CQ emits none — no diagnostic, exit 0. `clang`'s own
   `-Wuninitialized` still fires under `-Wall` (measured), and that is correct
   and deliberately untouched: the ruling attaches to the QUBIT ALLOCATION, not
   to the C variable, and CQ makes no claim about the object at all. The slice
   harness compiles at `-O1` without `-Wall`, so this build is silent.

   lit twin: `lowering_accept_undef_theta_seed_zero.ll` (this shape at `i1`).
   In-region sibling: `slice_undef_seed_in_region.c` (customer C2b).
   Probe of record: `$SES/trackU/probes/u3.c` (DIAG_2026-09-14.md Q2 row iii).

   The harness runs the binary under `set -euo pipefail`, so the body lives in
   `slice()` and `main` returns 0 — the house convention for this directory. */
#include "CQ.h"

int slice(void) {
    int a = 5;
    bool b;
    cq_theta(&b, 0.5);
    if (b) a -= 3;
    return cq_measure(b) + cq_measure(a);
}

int main(void) {
    (void) slice();
    return 0;
}
