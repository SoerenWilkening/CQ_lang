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

int32_t cqrt_alloc_f16(_Float16 value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_f16(%f) -> h%d\n", (double)value, h);
    fflush(stdout);
    return h;
}

int32_t cqrt_alloc_f80(long double value) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_f80(%Lf) -> h%d\n", value, h);
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

_Float16 cqrt_measure_f16(int32_t handle) {
    printf("cqrt_measure_f16(h%d) -> 0.000000\n", handle);
    fflush(stdout);
    return (_Float16)0;
}

long double cqrt_measure_f80(int32_t handle) {
    printf("cqrt_measure_f80(h%d) -> 0.000000\n", handle);
    fflush(stdout);
    return (long double)0;
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

void cqrt_ry_f16(int32_t handle, double angle) {
    printf("cqrt_ry_f16(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_ry_f80(int32_t handle, double angle) {
    printf("cqrt_ry_f80(h%d, %f)\n", handle, angle);
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

void cqrt_rz_f16(int32_t handle, double angle) {
    printf("cqrt_rz_f16(h%d, %f)\n", handle, angle);
    fflush(stdout);
}

void cqrt_rz_f80(int32_t handle, double angle) {
    printf("cqrt_rz_f80(h%d, %f)\n", handle, angle);
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

void cqrt_rz_f16_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f16_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_f80_controlled(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f80_controlled(h%d, h%d, %f)\n", ctrl, handle, angle);
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

void cqrt_rz_f16_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f16_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
    fflush(stdout);
}

void cqrt_rz_f80_controlled_inv(int32_t ctrl, int32_t handle, double angle) {
    printf("cqrt_rz_f80_controlled_inv(h%d, h%d, %f)\n", ctrl, handle, angle);
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
 * Controlled gate primitives (Phase 4, PRD §2.8).
 * The controlled gate forms prepend one i32 control-flag handle as arg 0
 * (PRD §1.2). Same no-arrow void trace as their uncontrolled twins; the
 * control flag prints as a leading h<N>. Not emitted by the IR pass
 * yet — declared + defined for Phase-8 completeness.
 * ------------------------------------------------------------------- */

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
 * per width. Copies src into the |0> dst rail iff the i32 control flag
 * ctrl is set (control flag arg-0); the tainted-`select` controlled-XOR
 * copy merge primitive emitted by SelectMergeEmit. A controlled-CNOT
 * involution (no _inv twin); never frees its source. Same no-arrow void
 * trace convention as cqrt_cswap; all three handle args print as h<N>.
 * The 5 integer widths plus — since the fp-DATA select un-staging
 * (fp-data-select-PRD, issue kjd1) — the 4 fp widths f16/f32/f64/f80:
 * the select merge's angle fence proves the fp value is data, and the
 * copy moves basis bit-pattern labels, so the fp width tags the symbol
 * name only (all args stay i32 handles; see cq_runtime.h). Every other
 * fp-under-control path still declines fp.
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

void cqrt_copy_f16_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_f16_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

void cqrt_copy_f32_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_f32_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

void cqrt_copy_f64_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_f64_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

void cqrt_copy_f80_controlled(int32_t ctrl, int32_t src, int32_t dst) {
    printf("cqrt_copy_f80_controlled(h%d, h%d, h%d)\n", ctrl, src, dst);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * In-place reversible arithmetic — immediate operand (issue dtzb). The
 * rail register `h` is MUTATED in place by the classical immediate; the
 * handle is unchanged (no fresh rail), matching Bennett.jl's in-place
 * adder. Trace-only: print the symbol, the handle as h<N>, and the
 * immediate as a decimal literal (cast to long long like cqrt_alloc).
 * --------------------------------------------------------------------- */
void cqrt_addc_i1(int32_t h, bool imm) {
    printf("cqrt_addc_i1(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_addc_i8(int32_t h, int8_t imm) {
    printf("cqrt_addc_i8(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_addc_i16(int32_t h, int16_t imm) {
    printf("cqrt_addc_i16(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_addc_i32(int32_t h, int32_t imm) {
    printf("cqrt_addc_i32(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_addc_i64(int32_t h, int64_t imm) {
    printf("cqrt_addc_i64(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_xorc_i1(int32_t h, bool imm) {
    printf("cqrt_xorc_i1(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_xorc_i8(int32_t h, int8_t imm) {
    printf("cqrt_xorc_i8(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_xorc_i16(int32_t h, int16_t imm) {
    printf("cqrt_xorc_i16(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_xorc_i32(int32_t h, int32_t imm) {
    printf("cqrt_xorc_i32(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}
void cqrt_xorc_i64(int32_t h, int64_t imm) {
    printf("cqrt_xorc_i64(h%d, %lld)\n", h, (long long)imm);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Reversible I/O output tape (Phase 7.6, PRD-7.6 §2.8) — FROZEN core
 * ABI. `cqrt_tape_alloc` mints a tape handle (printed `t<N>`); each
 * `cqrt_tape_write_<W>` appends `src` as a fresh kept |0> output rail
 * and returns its handle (printed `h<N>`). Both draw from the shared
 * monotonic `cqrt_alloc_handle()` counter so tape and rail handles stay
 * globally ordered; only the print prefix (`t` vs `h`) differs. The
 * write is handle-RETURNING (the kept out-rail), unlike void cqrt_copy.
 * Trace-only: no simulation, no measurement (see cq_runtime.h).
 * ------------------------------------------------------------------- */

int32_t cqrt_tape_alloc(void) {
    int32_t t = cqrt_alloc_handle();
    printf("cqrt_tape_alloc() -> t%d\n", t);
    fflush(stdout);
    return t;
}

int32_t cqrt_tape_write_i1(int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i1(t%d, h%d) -> h%d\n", tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i8(int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i8(t%d, h%d) -> h%d\n", tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i16(int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i16(t%d, h%d) -> h%d\n", tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i32(int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i32(t%d, h%d) -> h%d\n", tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i64(int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i64(t%d, h%d) -> h%d\n", tape, src, out);
    fflush(stdout);
    return out;
}

/* ---------------------------------------------------------------------
 * Controlled reversible I/O output tape (Phase 7.6 Increment 2, PRD-7.6
 * §2.8) — Tier-0 `if(q)printf`. The appended entry's CONTENT is committed
 * under the i32 control flag `ctrl` (arg 0; `ctrl` prints as a leading
 * h<N>, mirroring cqrt_copy_<W>_controlled). The entry is ALWAYS appended
 * (classical/deterministic tape length); only its content is conditional.
 * Handle-RETURNING like its uncontrolled twin (the kept out-rail). Same
 * monotonic handle counter; trace-only (no simulation, no measurement).
 * ------------------------------------------------------------------- */

int32_t cqrt_tape_write_i1_controlled(int32_t ctrl, int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i1_controlled(h%d, t%d, h%d) -> h%d\n", ctrl, tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i8_controlled(int32_t ctrl, int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i8_controlled(h%d, t%d, h%d) -> h%d\n", ctrl, tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i16_controlled(int32_t ctrl, int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i16_controlled(h%d, t%d, h%d) -> h%d\n", ctrl, tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i32_controlled(int32_t ctrl, int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i32_controlled(h%d, t%d, h%d) -> h%d\n", ctrl, tape, src, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_tape_write_i64_controlled(int32_t ctrl, int32_t tape, int32_t src) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_tape_write_i64_controlled(h%d, t%d, h%d) -> h%d\n", ctrl, tape, src, out);
    fflush(stdout);
    return out;
}

/* ---------------------------------------------------------------------
 * QRAM — tainted-index memory (Phase 7.5, PRD-7.5 §2.3) — FROZEN core
 * ABI. `cqrt_qram_alloc_<W>` mints an array handle (printed `a<N>`) from
 * the shared monotonic counter; only the `count` is recorded (cell
 * contents are classical metadata, §2.6). `cqrt_qram_load_<W>` copies the
 * cell at `idx` out into a fresh kept value handle (printed `h<N>`); the
 * `_unc` twin un-copies a dead loaded value back to |0> (void, no arrow).
 * Trace-only: no simulation, no measurement (Rule 5; see cq_runtime.h).
 * The store path lands in Increment 2.
 * ------------------------------------------------------------------- */

int32_t cqrt_qram_alloc_i1(int32_t count) {
    int32_t a = cqrt_alloc_handle();
    printf("cqrt_qram_alloc_i1(%d) -> a%d\n", count, a);
    fflush(stdout);
    return a;
}

int32_t cqrt_qram_alloc_i8(int32_t count) {
    int32_t a = cqrt_alloc_handle();
    printf("cqrt_qram_alloc_i8(%d) -> a%d\n", count, a);
    fflush(stdout);
    return a;
}

int32_t cqrt_qram_alloc_i16(int32_t count) {
    int32_t a = cqrt_alloc_handle();
    printf("cqrt_qram_alloc_i16(%d) -> a%d\n", count, a);
    fflush(stdout);
    return a;
}

int32_t cqrt_qram_alloc_i32(int32_t count) {
    int32_t a = cqrt_alloc_handle();
    printf("cqrt_qram_alloc_i32(%d) -> a%d\n", count, a);
    fflush(stdout);
    return a;
}

int32_t cqrt_qram_alloc_i64(int32_t count) {
    int32_t a = cqrt_alloc_handle();
    printf("cqrt_qram_alloc_i64(%d) -> a%d\n", count, a);
    fflush(stdout);
    return a;
}

int32_t cqrt_qram_load_i1(int32_t arr, int32_t idx) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_qram_load_i1(a%d, h%d) -> h%d\n", arr, idx, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_qram_load_i8(int32_t arr, int32_t idx) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_qram_load_i8(a%d, h%d) -> h%d\n", arr, idx, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_qram_load_i16(int32_t arr, int32_t idx) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_qram_load_i16(a%d, h%d) -> h%d\n", arr, idx, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_qram_load_i32(int32_t arr, int32_t idx) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_qram_load_i32(a%d, h%d) -> h%d\n", arr, idx, out);
    fflush(stdout);
    return out;
}

int32_t cqrt_qram_load_i64(int32_t arr, int32_t idx) {
    int32_t out = cqrt_alloc_handle();
    printf("cqrt_qram_load_i64(a%d, h%d) -> h%d\n", arr, idx, out);
    fflush(stdout);
    return out;
}

void cqrt_qram_load_i1_unc(int32_t out, int32_t arr, int32_t idx) {
    printf("cqrt_qram_load_i1_unc(h%d, a%d, h%d)\n", out, arr, idx);
    fflush(stdout);
}

void cqrt_qram_load_i8_unc(int32_t out, int32_t arr, int32_t idx) {
    printf("cqrt_qram_load_i8_unc(h%d, a%d, h%d)\n", out, arr, idx);
    fflush(stdout);
}

void cqrt_qram_load_i16_unc(int32_t out, int32_t arr, int32_t idx) {
    printf("cqrt_qram_load_i16_unc(h%d, a%d, h%d)\n", out, arr, idx);
    fflush(stdout);
}

void cqrt_qram_load_i32_unc(int32_t out, int32_t arr, int32_t idx) {
    printf("cqrt_qram_load_i32_unc(h%d, a%d, h%d)\n", out, arr, idx);
    fflush(stdout);
}

void cqrt_qram_load_i64_unc(int32_t out, int32_t arr, int32_t idx) {
    printf("cqrt_qram_load_i64_unc(h%d, a%d, h%d)\n", out, arr, idx);
    fflush(stdout);
}

/* Store path (Phase 7.5 Increment 2). `cqrt_qram_store_<W>` writes the value
 * handle `val` into the cell at the (quantum) index `idx`; it is VOID and
 * in-place on the arg-0 array handle (the displaced old value goes on the
 * backend's own tape, never recorded here — only the (arr, idx, val) ABI).
 * The `_unc` twin pops the backend's tape (same args; no arrow). Trace-only:
 * no simulation, no measurement (Rule 5). */

void cqrt_qram_store_i1(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i1(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i8(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i8(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i16(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i16(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i32(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i32(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i64(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i64(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i1_unc(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i1_unc(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i8_unc(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i8_unc(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i16_unc(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i16_unc(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i32_unc(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i32_unc(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

void cqrt_qram_store_i64_unc(int32_t arr, int32_t idx, int32_t val) {
    printf("cqrt_qram_store_i64_unc(a%d, h%d, h%d)\n", arr, idx, val);
    fflush(stdout);
}

/* ---------------------------------------------------------------------
 * Free — width-irrelevant.
 * ------------------------------------------------------------------- */

void cqrt_free(int32_t handle) {
    printf("cqrt_free(h%d)\n", handle);
    fflush(stdout);
}
