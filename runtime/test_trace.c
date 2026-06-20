/* test_trace.c — runtime-stub acceptance gate.
 *
 * Drives the runtime API directly and prints exactly the trace expected
 * by test_trace.expected.log; the runtime_trace_test ctest target diffs
 * the two byte-for-byte. This pins every alloc / measure / template /
 * free trace-line format before the IR pass or e2e fixtures begin to
 * consume them.
 *
 * Layout: the i32 carryover (i32 alloc + i32 Q+Q template add + i32
 * measure) runs first, preserving its original handle IDs (h0–h2) so
 * the existing worked-example slice of the golden is unchanged across
 * the widening. The 6 new widths (i1, i8, i16, i64, f32, f64) then
 * each exercise their alloc → measure pair in declaration order; the
 * monotonic handle counter walks h3..h8 across the 6 new allocs.
 *
 * Template stub exercise: after the alloc/measure walks, each of the
 * 14 template stubs (7 widths × {Q+Q, Q+C}) is exercised exactly once.
 * The existing line-24 `cq_template_add_i32(h0, h1)` call already
 * covers the i32 Q+Q variant, so the new block adds 13 calls:
 *   - For each non-i32 width (i1, i8, i16, i64, f32, f64): allocate a
 *     fresh second handle, call `cq_template_add_<W>` (Q+Q), then call
 *     `cq_template_add_<W>_hl` (Q+C) re-using the widened handle on
 *     the lhs.
 *   - For i32: a single `cq_template_add_i32_hl(h0, ...)` call closes
 *     the matrix (the Q+Q variant already ran on line 24).
 * Handles in the new block walk h9..h27 monotonically.
 *
 * Rotation exercise: after the template walk (which closes at h32),
 * one cqrt_ry_<W> + cqrt_rz_<W> pair runs per width. These are void
 * and mint NO handles — the counter stays at h32 — so each reuses an
 * existing handle of the matching width. The 4 gate placeholders
 * (cqrt_x/h/cnot/toffoli) are deliberately NOT exercised here.
 */
#include "cq_runtime.h"
#include "cq_templates.h"

int main(void) {
    /* --- i32 carryover (alloc/template/measure) ------------------- */
    int32_t h_a = cqrt_alloc_i32(3);
    int32_t h_b = cqrt_alloc_i32(5);
    int32_t h_c = cq_template_add_i32(h_a, h_b);
    (void) cqrt_measure_i32(h_c);

    /* --- width widening: alloc + measure for each new width.
     * Order matches cq_runtime.h declaration order minus i32. */
    int32_t h_i1  = cqrt_alloc_i1(true);
    (void) cqrt_measure_i1(h_i1);

    int32_t h_i8  = cqrt_alloc_i8((int8_t)127);
    (void) cqrt_measure_i8(h_i8);

    int32_t h_i16 = cqrt_alloc_i16((int16_t)1024);
    (void) cqrt_measure_i16(h_i16);

    int32_t h_i64 = cqrt_alloc_i64((int64_t)9000000000);
    (void) cqrt_measure_i64(h_i64);

    int32_t h_f32 = cqrt_alloc_f32(3.14f);
    (void) cqrt_measure_f32(h_f32);

    int32_t h_f64 = cqrt_alloc_f64(2.718281828);
    (void) cqrt_measure_f64(h_f64);

    /* --- exercise the 14 template stubs once each.
     * i32 Q+Q already ran above (h_c); each non-i32 width allocates a
     * fresh second operand handle, then exercises Q+Q + Q+C; i32 Q+C
     * closes the matrix using h_a as the lhs. */
    int32_t h_i1_b  = cqrt_alloc_i1(false);
    (void) cq_template_add_i1(h_i1, h_i1_b);
    (void) cq_template_add_i1_hl(h_i1, true);

    int32_t h_i8_b  = cqrt_alloc_i8((int8_t)42);
    (void) cq_template_add_i8(h_i8, h_i8_b);
    (void) cq_template_add_i8_hl(h_i8, (int8_t)42);

    int32_t h_i16_b = cqrt_alloc_i16((int16_t)1000);
    (void) cq_template_add_i16(h_i16, h_i16_b);
    (void) cq_template_add_i16_hl(h_i16, (int16_t)1000);

    (void) cq_template_add_i32_hl(h_a, 99);

    int32_t h_i64_b = cqrt_alloc_i64((int64_t)12345);
    (void) cq_template_add_i64(h_i64, h_i64_b);
    (void) cq_template_add_i64_hl(h_i64, (int64_t)12345);

    int32_t h_f32_b = cqrt_alloc_f32(1.5f);
    (void) cq_template_fadd_f32(h_f32, h_f32_b);
    (void) cq_template_fadd_f32_hl(h_f32, 1.5f);

    int32_t h_f64_b = cqrt_alloc_f64(2.5);
    (void) cq_template_fadd_f64(h_f64, h_f64_b);
    (void) cq_template_fadd_f64_hl(h_f64, 2.5);

    /* --- exercise one symbol per new family (sub, xor, icmp, sext,
     * fneg). Reuses earlier handles; each call allocates one fresh
     * handle (h28..h32). */
    (void) cq_template_sub_i32(h_a, h_b);
    (void) cq_template_xor_i32(h_a, h_b);
    (void) cq_template_icmp_slt_i32(h_a, h_b);
    (void) cq_template_sext_i8_to_i32(h_i8);
    (void) cq_template_fneg_f64(h_f64);

    /* --- exercise the 7 ry + 7 rz rotation symbols, one pair per
     * width. These are void and mint NO handles, so the monotonic
     * counter stays at h32 throughout this block; each call reuses an
     * existing handle of the matching width. The 4 gate placeholders
     * (cqrt_x/h/cnot/toffoli) are intentionally left unexercised —
     * they are declared + defined but not emitted until Phase 8.
     * Angle 0.785398 prints byte-exact at %f's default 6 digits. */
    cqrt_ry_i1(h_i1, 0.785398);
    cqrt_rz_i1(h_i1, 0.785398);
    cqrt_ry_i8(h_i8, 0.785398);
    cqrt_rz_i8(h_i8, 0.785398);
    cqrt_ry_i16(h_i16, 0.785398);
    cqrt_rz_i16(h_i16, 0.785398);
    cqrt_ry_i32(h_a, 0.785398);
    cqrt_rz_i32(h_a, 0.785398);
    cqrt_ry_i64(h_i64, 0.785398);
    cqrt_rz_i64(h_i64, 0.785398);
    cqrt_ry_f32(h_f32, 0.785398);
    cqrt_rz_f32(h_f32, 0.785398);
    cqrt_ry_f64(h_f64, 0.785398);
    cqrt_rz_f64(h_f64, 0.785398);

    /* --- npu.4 smoke: the controlled-SWAP / Fredkin primitive. Unlike the
     * Phase-8 gate placeholders, cqrt_cswap IS emitted by the IR pass (the
     * MUX-EXCH gated-switch lowering), so its trace format is pinned here.
     * Void, mints no handle (counter stays at h32); reuses existing handles. */
    cqrt_cswap(h_i1, h_a, h_i8);

    /* --- 4.2 WI-1 smoke: the per-width reversible basis copy (PRD
     * Part II §8.1) — the value-arm method-B copy-out primitive,
     * emitted by the swap-route lowering. The 5 integer widths only
     * (no FP twins exist — an FP merge phi under tainted control is
     * an angle, never data). Void, mints no handle (counter stays at
     * h32); each call reuses existing handles of the matching width
     * (src = the first alloc of the width, dst = the second). */
    cqrt_copy_i1(h_i1, h_i1_b);
    cqrt_copy_i8(h_i8, h_i8_b);
    cqrt_copy_i16(h_i16, h_i16_b);
    cqrt_copy_i32(h_a, h_b);
    cqrt_copy_i64(h_i64, h_i64_b);

    /* --- 4.4 WI-2 smoke: the controlled per-width reversible basis copy
     * (PRD Part IV §16.3) — the tainted-`select` controlled-XOR copy
     * merge primitive, emitted by SelectMergeEmit. The 5 integer widths
     * only (no FP twins exist — an FP merge phi under tainted control is
     * an angle, never data). Void, mints no handle (counter stays at
     * h32); the control flag (arg-0) reuses h_c, src/dst reuse the same
     * existing handles as the uncontrolled copy block above. */
    cqrt_copy_i1_controlled(h_c, h_i1, h_i1_b);
    cqrt_copy_i8_controlled(h_c, h_i8, h_i8_b);
    cqrt_copy_i16_controlled(h_c, h_i16, h_i16_b);
    cqrt_copy_i32_controlled(h_c, h_a, h_b);
    cqrt_copy_i64_controlled(h_c, h_i64, h_i64_b);

    /* --- Phase 7.1 Increment D smoke: half-precision (f16). f16 rides the
     * fp rotation-lowering path — alloc / measure / ry / rz + the fadd Q+Q
     * and Q+C templates — but has NO cqrt_copy_f16 (an f16 merge phi under
     * tainted control is an angle, never data; the fp-angle fence). Appended
     * at the end so every existing handle ID (h0..h32) is unchanged; the
     * monotonic counter resumes at h33. 1.5 and 0.5 are exactly representable
     * in f16, so the (double)-promoted %f prints byte-stable. */
    int32_t h_f16   = cqrt_alloc_f16((_Float16)1.5);   /* h33 */
    (void) cqrt_measure_f16(h_f16);
    int32_t h_f16_b = cqrt_alloc_f16((_Float16)0.5);   /* h34 */
    (void) cq_template_fadd_f16(h_f16, h_f16_b);        /* h35 */
    (void) cq_template_fadd_f16_hl(h_f16, (_Float16)1.5); /* h36 */
    cqrt_ry_f16(h_f16, 0.785398);
    cqrt_rz_f16(h_f16, 0.785398);

    return 0;
}
