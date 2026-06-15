/* cq_runtime.c — trace-only runtime stub.
 *
 * See cq_runtime.h for the spec.
 *
 * Each entry point prints exactly one '\n'-terminated trace line to
 * stdout and flushes, so the trace stays well-ordered with any other
 * stdout traffic from the host binary. Trace-line formats are locked
 * byte-exact by runtime_trace_test (the test_trace driver +
 * test_trace.expected.log golden).
 *
 * Format conventions:
 *   - handle:  h<N>           (printed as %d of int32_t handle id)
 *   - ints:    %lld           (value cast to long long, uniform across
 *                              all int widths so the format string does
 *                              not fork per width)
 *   - floats:  %f             (default 6-digit precision; float promotes
 *                              to double via varargs)
 *   - _Bool:   %d             (printed as 0/1 — only the i1 alloc body)
 *
 * Measure bodies print the zero return value as a literal in the trace
 * ("0" for ints, "0.000000" for floats). This is byte-identical to
 * formatting (long long)0 with %lld and 0.0 with %f respectively, and
 * matches the original cqrt_measure_i32 convention.
 *
 * cqrt_free's trace-line format: this module emits "cqrt_free(h<N>)"
 * with NO "-> void" suffix. The arrow notation in the trace format
 * exists to carry a return value; with no return there is nothing to
 * write after the parens, so we omit the arrow. Documented here so
 * the convention is discoverable from one place.
 */
#include "cq_runtime.h"

#include <stdio.h>

/* Process-global handle counter. Shared between every cqrt_alloc_<W>
 * here and every cq_template_add_<W>* in the templates module via the
 * cqrt_alloc_handle() helper, so handles stay globally monotonic
 * regardless of which width / which module issues them. */
static int32_t next_handle = 0;

int32_t cqrt_alloc_handle(void) {
    return next_handle++;
}

/* ---------------------------------------------------------------------
 * Allocation bodies — one per width.
 * ------------------------------------------------------------------- */

int32_t cqrt_alloc_i1(bool value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i1(%d) -> h%d\n", (int)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i8(int8_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i8(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i16(int16_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i16(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i32(int32_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i32(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_i64(int64_t value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i64(%lld) -> h%d\n", (long long)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_f32(float value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_f32(%f) -> h%d\n", (double)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_f64(double value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_f64(%f) -> h%d\n", value, h);
    fflush(stdout);
    return h;
}

/* ---------------------------------------------------------------------
 * Measure bodies — one per width. Return zero of the matching width
 * (the runtime is trace-only, no simulation). Zero is printed as
 * a literal to keep all measure bodies uniform and match the original
 * cqrt_measure_i32 convention; byte-identical to %lld of (long long)0
 * for ints and %f of 0.0 for floats.
 * ------------------------------------------------------------------- */

bool cqrt_measure_i1(int32_t handle) {
    printf("cqrt_measure_i1(h%d) -> 0\n", handle);
    fflush(stdout);
    return false;
}

int8_t cqrt_measure_i8(int32_t handle) {
    printf("cqrt_measure_i8(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

int16_t cqrt_measure_i16(int32_t handle) {
    printf("cqrt_measure_i16(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

int32_t cqrt_measure_i32(int32_t handle) {
    printf("cqrt_measure_i32(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

int64_t cqrt_measure_i64(int32_t handle) {
    printf("cqrt_measure_i64(h%d) -> 0\n", handle);
    fflush(stdout);
    return 0;
}

float cqrt_measure_f32(int32_t handle) {
    printf("cqrt_measure_f32(h%d) -> 0.000000\n", handle);
    fflush(stdout);
    return 0.0f;
}

double cqrt_measure_f64(int32_t handle) {
    printf("cqrt_measure_f64(h%d) -> 0.000000\n", handle);
    fflush(stdout);
    return 0.0;
}

/* ---------------------------------------------------------------------
 * Ry rotation bodies — one per width. Void; like cqrt_free, no "-> "
 * arrow (nothing to return). The handle prints as h<N>, the angle as
 * %f (default 6-digit precision, matching the float trace format).
 * ------------------------------------------------------------------- */

void cqrt_ry_i1(int32_t handle, double angle) {
    printf("cqrt_ry_i1(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_ry_i8(int32_t handle, double angle) {
    printf("cqrt_ry_i8(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_ry_i16(int32_t handle, double angle) {
    printf("cqrt_ry_i16(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_ry_i32(int32_t handle, double angle) {
    printf("cqrt_ry_i32(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_ry_i64(int32_t handle, double angle) {
    printf("cqrt_ry_i64(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_ry_f32(int32_t handle, double angle) {
    printf("cqrt_ry_f32(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_ry_f64(int32_t handle, double angle) {
    printf("cqrt_ry_f64(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Rz rotation bodies — one per width. Same shape as Ry.
 * ------------------------------------------------------------------- */

void cqrt_rz_i1(int32_t handle, double angle) {
    printf("cqrt_rz_i1(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_rz_i8(int32_t handle, double angle) {
    printf("cqrt_rz_i8(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_rz_i16(int32_t handle, double angle) {
    printf("cqrt_rz_i16(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_rz_i32(int32_t handle, double angle) {
    printf("cqrt_rz_i32(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_rz_i64(int32_t handle, double angle) {
    printf("cqrt_rz_i64(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_rz_f32(int32_t handle, double angle) {
    printf("cqrt_rz_f32(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_rz_f64(int32_t handle, double angle) {
    printf("cqrt_rz_f64(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Controlled Rz rotation bodies (Phase 4, PRD §2.8) — one per width ×
 * {controlled, controlled_inv}. The control flag is argument 0 and
 * prints as a leading h<N>; otherwise identical no-arrow void trace as
 * the uncontrolled rz. Declared + defined this phase; the IR pass emits
 * these from WP3 onward (controlled gate-body substitution).
 * ------------------------------------------------------------------- */

void cqrt_rz_i1_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i1_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i8_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i8_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i16_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i16_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i32_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i32_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i64_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i64_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_f32_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f32_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_f64_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f64_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i1_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i1_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i8_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i8_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i16_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i16_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i32_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i32_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_i64_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_i64_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_f32_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f32_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_f64_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f64_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Controlled Ry inverse (npu.6) — uncompute a non-selected source's
 * single-Ry prep in the gated-switch MUX-EXCH lowering. Mirrors the
 * controlled rz inverse block above; only the `ry` stem differs.
 * --------------------------------------------------------------------- */
void cqrt_ry_i1_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_ry_i1_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_ry_i8_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_ry_i8_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_ry_i16_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_ry_i16_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_ry_i32_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_ry_i32_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_ry_i64_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_ry_i64_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_ry_f32_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_ry_f32_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_ry_f64_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_ry_f64_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Gate primitives (backend.md §11.4) — handle-typed, void. Declared +
 * defined this phase but NOT emitted by the IR pass yet (Phase 8), so
 * they are left unexercised by the trace driver. Same no-arrow void
 * trace convention as cqrt_free; args printed as h<N>.
 * ------------------------------------------------------------------- */

void cqrt_x(int32_t q) {
    printf("cqrt_x(h%d)\n", q);
    fflush(stdout);
}

void cqrt_h(int32_t q) {
    printf("cqrt_h(h%d)\n", q);
    fflush(stdout);
}

void cqrt_cnot(int32_t ctrl, int32_t tgt) {
    printf("cqrt_cnot(h%d, h%d)\n", ctrl, tgt);
    fflush(stdout);
}

void cqrt_toffoli(int32_t c1, int32_t c2, int32_t tgt) {
    printf("cqrt_toffoli(h%d, h%d, h%d)\n", c1, c2, tgt);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Controlled gate primitives + Toffoli inverse (Phase 4, PRD §2.8).
 * cqrt_toffoli_inv uncomputes a flag conjunction (PRD §2.5/§2.7); the
 * controlled gate forms prepend one i32 control-flag handle as arg 0
 * (PRD §1.2). Same no-arrow void trace as their uncontrolled twins; the
 * control flag prints as a leading h<N>. Not emitted by the IR pass
 * yet — declared + defined for Phase-8 / flag-conjunction completeness.
 * ------------------------------------------------------------------- */

void cqrt_toffoli_inv(int32_t c1, int32_t c2, int32_t tgt) {
    printf("cqrt_toffoli_inv(h%d, h%d, h%d)\n", c1, c2, tgt);
    fflush(stdout);
}

void cqrt_x_controlled(int32_t ctrl, int32_t q) {
    printf("cqrt_x_controlled(h%d, h%d)\n", ctrl, q);
    fflush(stdout);
}

void cqrt_h_controlled(int32_t ctrl, int32_t q) {
    printf("cqrt_h_controlled(h%d, h%d)\n", ctrl, q);
    fflush(stdout);
}

void cqrt_cnot_controlled(int32_t ctrl, int32_t target_ctrl, int32_t tgt) {
    printf("cqrt_cnot_controlled(h%d, h%d, h%d)\n", ctrl, target_ctrl, tgt);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Controlled-SWAP / Fredkin (npu.4) — swaps a and b iff ctrl is set.
 * PURE self-inverse Fredkin: it frees NOTHING and allocates nothing
 * (SCOPING §2/§3a, PRD Part II §8.2/§8.5). The swap-route emitters
 * depend on that: every region issues route/route-back (+ R-dagger)
 * cswap pairs over live registers and frees the work rail exactly once,
 * separately — a cswap that freed an operand would double-free the rail
 * and hidden-measure the routed register. (An earlier MUX-EXCH/npu.5
 * sentence here described a move-and-free composite from the excised
 * controlled-op design, 7cde677 — struck 2026-06-11; never revive it as
 * the primitive's semantics.) Trace prints all three handle args as
 * h<N>; SWAP is its own inverse (no _inv twin).
 * ------------------------------------------------------------------- */

void cqrt_cswap(int32_t ctrl, int32_t a, int32_t b) {
    printf("cqrt_cswap(h%d, h%d, h%d)\n", ctrl, a, b);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Reversible basis copy (Phase 4.2, PRD Part II §8.1) — one per integer
 * width. Keep-sources-live transversal-CNOT copy |x>|0> -> |x>|x>; an
 * involution (no _inv twin); never frees its source. Emitted by the
 * value-arm (method-B) swap-route lowering as its copy-out step. Same
 * no-arrow void trace convention as cqrt_cswap; both handles print as
 * h<N>. Integer widths only — an FP merge phi under tainted control is
 * an angle, never data, so no f32/f64 twins exist (see cq_runtime.h).
 * ------------------------------------------------------------------- */

void cqrt_copy_i1(int32_t src, int32_t dst) {
    printf("cqrt_copy_i1(h%d, h%d)\n", src, dst);
    fflush(stdout);
}

void cqrt_copy_i8(int32_t src, int32_t dst) {
    printf("cqrt_copy_i8(h%d, h%d)\n", src, dst);
    fflush(stdout);
}

void cqrt_copy_i16(int32_t src, int32_t dst) {
    printf("cqrt_copy_i16(h%d, h%d)\n", src, dst);
    fflush(stdout);
}

void cqrt_copy_i32(int32_t src, int32_t dst) {
    printf("cqrt_copy_i32(h%d, h%d)\n", src, dst);
    fflush(stdout);
}

void cqrt_copy_i64(int32_t src, int32_t dst) {
    printf("cqrt_copy_i64(h%d, h%d)\n", src, dst);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Controlled reversible basis copy (Phase 4.4, PRD Part IV §16.3) — one
 * per integer width. Copies src into the |0> dst rail iff the i32
 * control flag ctrl is set (control flag arg-0); the tainted-`select`
 * controlled-XOR copy merge primitive emitted by SelectMergeEmit. A
 * controlled-CNOT involution (no _inv twin); never frees its source.
 * Same no-arrow void trace convention as cqrt_cswap; all three handle
 * args print as h<N>. Integer widths only — an FP merge phi under
 * tainted control is an angle, never data (see cq_runtime.h).
 * ------------------------------------------------------------------- */

void cqrt_copy_i1_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_i1_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

void cqrt_copy_i8_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_i8_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

void cqrt_copy_i16_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_i16_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

void cqrt_copy_i32_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_i32_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

void cqrt_copy_i64_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_i64_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Free — width-irrelevant.
 * ------------------------------------------------------------------- */

void cqrt_free(int32_t handle) {
    printf("cqrt_free(h%d)\n", handle);
    fflush(stdout);
}
