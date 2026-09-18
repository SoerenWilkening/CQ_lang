/* slice_control_predmux_rail_leaf.c — bd test_C_libtooling-fn1q, increment 2.
 *
 * THE BARE `_Bool` RAIL AS A MULTI-VALUE REGION'S CONDITION, FROM C.
 *
 *     bool b = cq_theta(b, 0.5);
 *     if (b) { A -= 3; B -= 4; C -= 5; D -= 6; }
 *
 * This is bd test_C_libtooling-s9xi's exhibit, and the thing to understand about
 * it is that it is the SAME PROGRAM as its two-variable sibling, which has lowered
 * since Phase 4.4. `clang -O1` if-converts the two-variable form into plain
 * `select`s; at four it exceeds its speculation budget, leaves a real `br`, and
 * the region declined `control flow`. One construct, two verdicts, decided by an
 * -O1 heuristic (Rule 9 — measured 2026-09-23, not inferred).
 *
 * ⚠ FOUR IS NOT A MAGIC NUMBER AND MUST NOT BE READ AS ONE. It is simply a count
 * -O1's if-conversion refuses on this machine's LLVM 19. If a future -O1
 * if-converted four, this slice would keep PASSING while silently testing the
 * already-shipped select path instead of the new one — the failure mode a golden
 * cannot see. The IR fixtures control_predmux_accept_rail_leaf_{cond,negation}.ll
 * pin the `br` shape directly and are what would still catch it; this slice pins
 * that the shape is reachable from ordinary C at all.
 *
 * WHAT THE TRACE SHOWS. One allocation and one Ry for the user's `_Bool`, then
 * FOUR independent merges, each: a fresh |0> ancilla, a CNOT copy of the rail onto
 * it, a fresh |0> target, two X-bracketed `cqrt_copy_i32_controlled`, the CNOT
 * restored, and `cqrt_free` at a proven |0> (x XOR x = 0 on every branch).
 *
 * ⚠ THE RAIL IS NEVER BRACKETED AND NEVER FREED. It is the user's own register:
 * read only as a CONTROL, and measured by the user at the end (Rule 6). The
 * `cqrt_x` pairs in the trace are all on the ANCILLAS — check the handle numbers
 * before reading a bracket as being on `b`.
 *
 * `main` returns 0: an e2e slice whose main returns nonzero fails under
 * `set -o pipefail` with ZERO bytes of output and no diff (bd memory
 * `e2e-slice-main-return-value-trap`).
 */
#include "CQ.h"

static int slice(void) {
    int A = 5, B = 6, C = 7, D = 8;
    bool b = 0;
    b = cq_theta(b, 0.5);
    if (b) { A -= 3; B -= 4; C -= 5; D -= 6; }
    return cq_measure(A) + cq_measure(B) + cq_measure(C) + cq_measure(D)
         + cq_measure(b);
}

int main(void) { (void)slice(); return 0; }
