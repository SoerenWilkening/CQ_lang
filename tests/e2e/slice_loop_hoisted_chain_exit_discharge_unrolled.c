/* slice_loop_hoisted_chain_exit_discharge_unrolled.c — THE HAND-UNROLLED TWIN of
   `slice_loop_hoisted_chain_exit_discharge.c` (bd `test_C_libtooling-tu9q` P2,
   closing bd `test_C_libtooling-1m5p`). Same program with the 2-trip loop written
   out; it is the CIRCUIT THE ROLLED FORM DENOTES.

   ⚠ WHAT THIS TWIN IS FOR, AND WHAT IT IS NOT. It ALWAYS discharged the hoisted
   `sqrt` chain — on the ORACLE and on the subject — which is exactly why it is the
   reference: the rolled form was missing a `cq_template_sqrt_f64_unc` this one
   emitted, 26 lines against 28. So the pair's job is to make the ROLLED side's
   omission visible, and it did.

   ⚠ THERE IS DELIBERATELY NO `*-twin-identical` GATE. The two goldens are
   MULTISET-IDENTICAL and ORDER-DIVERGENT by construction: the rolled form
   discharges the chain at the LOOP EXIT, this one at function scope after the last
   copy. A `compare_files` gate would be RED, and a gate expected to be red is a
   gate people stop reading (CLAUDE.md L10). The claim the pair carries is COUNT +
   MULTISET + a commutation argument, written in the rolled slice's header and in
   `tests/e2e/CMakeLists.txt` at the registration — never byte identity (owner
   ruling S3, 2026-09-17).

   ⚠ STRICT stage 2b here, and the ASYMMETRY IS THE POINT: this twin reports
   `5 verified, 0 unproven` while the rolled slice reports `1 verified, 3 unproven`
   and needs `--allow-unproven`. Nothing about the rolled circuit is less proven —
   `free_pairing_check.py` analyses per straight-line STREAM and a loop-exit
   discharge is cross-stream BY CONSTRUCTION. The two numbers together are the
   measurement of the instrument's reach; neither alone is a statement about the
   rail. */
#include <math.h>

volatile int off = 3;

int slice(void) {
    int a = 0;
    int r = 0;
    cq_theta(&a, 0.5);
    cq_theta(&r, 0.3);
    if (sqrt(a + 3.) <= (double)off) { cq_theta(&r, 0.9); }
    if (sqrt(a + 3.) <= (double)off) { cq_theta(&r, 0.9); }
    cq_theta(&a, 0.7);
    return cq_measure(a) + cq_measure(r);
}

int main(void) { (void)slice(); return 0; }
