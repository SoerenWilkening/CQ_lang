/* slice_control_value_arm_cone.c — bd test_C_libtooling-fn1q, increment 1.
 *
 * THE VALUE ARM'S CLASSICAL CONE, FROM C. `if (q > 5) p += (k*3 + 7) ^ 5;`
 *
 * ⚠ THIS SLICE EXISTS BECAUSE example/ IS NOT IN THE REPOSITORY (bd
 * test_C_libtooling-zwtm): the decline this increment removes, and a fortnight-old
 * frontend break beside it, both surfaced only when the owner ran a script by
 * hand, because no gate in the tree compiles example/. Whatever the C-level story
 * is, it has to be pinned by a TRACKED file or the next frontend change breaks it
 * in silence again.
 *
 * WATCH WHAT clang -O1 DOES, because it is the whole reason the shape is common
 * (Rule 9): it SINKS the branch-invariant `(k*3+7)^5` INTO the arm, so this source
 * and `int t = (k*3+7)^5; if (q > 5) p += t;` produce BYTE-IDENTICAL stage-1 IR —
 * measured 2026-09-22. The cone is not an exotic spelling; it is what -O1 hands
 * the pass for the ordinary one.
 *
 * `k` is a mutable global, so the load survives -O1 and is genuinely a RUN-TIME
 * classical value — it reaches the template in the `_hl` literal slot and is NEVER
 * allocated a rail (the "do NOT promote a classical operand to a qubit handle"
 * prohibition). The four cone instructions emit NO GATE, which is why this trace
 * is exactly the pre-hoisted twin's; the IR pair
 * control_swap_value_accept_arm_cone{,_prehoisted_twin}.ll asserts that identity
 * mechanically.
 *
 * ⚠ READ THE `2` IN THE GOLDEN AS EVIDENCE, NOT AS A CONSTANT THE COMPILER FOLDED.
 * `cq_template_add_i32_hl(h1, 2)` carries `(k*3 + 7) ^ 5` = `(0*3+7)^5` = 2,
 * computed AT RUN TIME by the hoisted cone — the lowered module still holds the
 * `load i32, ptr @k` / `mul` / `add` / `xor` as ordinary classical IR (verified in
 * the stage-2 output, not inferred). If a future `-O1` const-folded `@k`, the
 * golden would be UNCHANGED while the slice stopped exercising anything; the IR
 * twin pair is what would still see it, which is why both gates exist.
 *
 * `main` returns 0 rather than the measured value: an e2e slice whose main returns
 * nonzero fails under `set -o pipefail` with ZERO bytes of output and no diff
 * (bd memory `e2e-slice-main-return-value-trap`).
 */
#include "CQ.h"

int k;

static int slice(void) {
    int q = 0;
    q = cq_theta(q, 0.5);
    int p = 0;
    p = cq_theta(p, 0.25);
    if (q > 5) { p += (k * 3 + 7) ^ 5; }
    return cq_measure(p);
}

int main(void) { (void)slice(); return 0; }
