/* slice_control_abort.c — Phase 7.2 Increment 3 e2e smoke (test_C_libtooling-65wb.3):
   the controlled abort/exit PARK CASCADE (PRD-7.2 §2.8 / §2.11-B), the only test
   layer that LINKS and so the ONLY proof that the park sequence's symbols
   (cqrt_cswap + cqrt_tape_alloc + cqrt_tape_write_i1) resolve and signature-match
   against libcq_runtime (Rule 2, Rule 16) — verify-clean and "runs without
   crashing" prove neither. NO new frozen symbol is minted (§2.8 truncation reuses
   cqrt_tape_write_i1 + a backend truncate-at-inspection convention).

   SOURCE INTENT — a tainted-condition early abort, the verified -O1 shape:
       q : tainted quantum handle (condition register, cq_theta == Ry)
       if (q > 5) abort();           // recognized noreturn sink + unreachable
       return cq_measure(q);         // the ordinary uncontrolled remainder

   At -O1 the abort arm survives as `{tail call void @abort(); unreachable}` (NO
   value, NO merge phi -> NON-reconverging), so it cannot match recoverRegion's
   accept shapes; classifyAbortPark recognizes it FIRST (before the OffPattern
   decline) and lowers the park cascade:
     - mint the abort flag from q0  (cq_template_icmp_sgt_i32_hl)
     - alloc the |0> graveyard rail (cqrt_alloc_i32(0))
     - cqrt_cswap(flag, q, grave)   -> move the would-abort component aside
     - cqrt_tape_write_i1(tape, flag) -> record the abort marker on the output tape
     - run the remainder UNCONTROLLED (abort terminates -> no coherent downstream,
       so the branch-correlated tail-garbage never dephases, §2.8/§2.9)
   The abort call + unreachable are ERASED; the graveyard rail + flag are KEPT,
   NEVER cqrt_free'd (a parked entangled rail freed dirty is a hidden measurement,
   Rule 6). The §2-A do-not-uncompute GraveyardRails set, subtracted at BOTH
   uncompute spine sites, is what keeps the whole-DAG driver from ever reversing or
   freeing them — observable here as the ABSENCE of any cqrt_free in the golden.

   WHY THE TRACE IS DETERMINISTIC: the runtime is trace-only and the lowered body
   is straight-line (the branch became an unconditional fall-through to the
   remainder), so every emitted gate fires unconditionally; cqrt_measure returns 0
   (no simulation). The golden pins the trace captured from REAL linked output
   (templates BEFORE runtime — load-bearing link order). cq_theta / cq_measure /
   abort resolve from CQ.h + <stdlib.h>, force-included by run_slice.sh. */
#include <stdlib.h>

int slice(void) {
    int q = cq_theta(5, 0.5);      /* taint q -> condition handle (alloc, ry)   */
    if (q > 5) abort();            /* controlled noreturn sink -> park cascade   */
    return cq_measure(q);          /* the ordinary uncontrolled remainder        */
}
int main(void) { (void) slice(); return 0; }
