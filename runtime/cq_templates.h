/* cq_templates.h — Phase 2 trace-only template stubs.
 *
 * Declares the 14 `cq_template_add_*` stubs: for each of 7 widths
 * (i1, i8, i16, i32, i64, f32, f64) two variants — Q+Q (`_iW`/`_fW`,
 * both operands tainted quantum handles) and Q+C (`_iW_hl`/`_fW_hl`,
 * handle on the left, width-typed classical literal on the right).
 * Every variant returns a fresh handle (via cqrt_alloc_handle in
 * cq_runtime) so handle numbering stays globally monotonic with
 * libcq_runtime.
 *
 * Phase 1 shipped only cq_template_add_i32 / _i32_hl; Phase 2 adds 12
 * new declarations (the other 6 width pairs). Bodies for the new 12
 * land in M07; only the existing two i32 bodies are linkable today
 * (see cq_templates.c).
 *
 * Width unification at the runtime ABI mirrors libcq_runtime: signedness
 * is a frontend-only concept (it threads through TypeMap's mid-struct
 * choice and Clang's opcode selection at the call site). The runtime
 * sees widths only, so both `signed char` and `unsigned char` patterns
 * dispatch to cq_template_add_i8 / cq_template_add_i8_hl. See
 * phases/phase2/PRD.md §"Stub template library" (lines 153-176) and
 * §"Width unification" (line 147) for the load-bearing rationale.
 *
 * Spec: phases/phase2/PRD.md §"Stub template library"; phases/phase2/PLAN.md §4.5.
 */
#ifndef CQ_TEMPLATES_H_
#define CQ_TEMPLATES_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* --- i1 (bool) ---------------------------------------------------------
 *
 * Trace formats (set in M07, per PLAN.md §6.6):
 *   Q+Q: "cq_template_add_i1(h<lhs>, h<rhs>) -> h<N>"
 *   Q+C: "cq_template_add_i1_hl(h<lhs>, <rhs>) -> h<N>"
 * `bool` (via <stdbool.h>) is the C alias for `_Bool` used in the
 * PRD — same `bool`/`_Bool` ABI consideration as the cq_runtime
 * i1 surface; we use `bool` for header consistency. */
int32_t cq_template_add_i1(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i1_hl(int32_t a_handle, bool b_classical);

/* --- i8 ---------------------------------------------------------------- */
int32_t cq_template_add_i8(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i8_hl(int32_t a_handle, int8_t b_classical);

/* --- i16 --------------------------------------------------------------- */
int32_t cq_template_add_i16(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i16_hl(int32_t a_handle, int16_t b_classical);

/* --- i32 (Phase 1 carryovers; bodies in cq_templates.c) --------------- */

/* Trace: "cq_template_add_i32(h<lhs>, h<rhs>) -> h<N>". Both args are
 * tainted quantum handles (Q+Q add). The IR pass dispatches to this
 * variant when both `add i32` operands are SSA values in the taint
 * set. */
int32_t cq_template_add_i32(int32_t lhs, int32_t rhs);

/* Trace: "cq_template_add_i32_hl(h<lhs>, <rhs>) -> h<N>" — note the
 * lack of an `h` prefix on the rhs: it's a classical literal, not a
 * handle. Used for mixed Q+C add patterns (`quantum int d = a + 5;`
 * or `quantum int e = a + classic;` where classical operands fold to
 * an LLVM ConstantInt). The IR pass dispatches to this variant when
 * the rhs of a tainted `add i32` is a ConstantInt. Per PLAN.md §6.6
 * the trace text mirrors the symbol name, so Q+C lines carry the
 * `_hl` suffix; readers distinguish Q+Q vs Q+C by BOTH the symbol
 * name AND the `h`-prefix (handle) vs bare literal on the rhs. Never
 * promote the literal to a handle (would conflict with the planned
 * cq_alloc optimization). */
int32_t cq_template_add_i32_hl(int32_t lhs_handle, int32_t rhs_literal);

/* --- i64 --------------------------------------------------------------- */
int32_t cq_template_add_i64(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i64_hl(int32_t a_handle, int64_t b_classical);

/* --- f32 --------------------------------------------------------------- */
int32_t cq_template_add_f32(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_f32_hl(int32_t a_handle, float b_classical);

/* --- f64 --------------------------------------------------------------- */
int32_t cq_template_add_f64(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_f64_hl(int32_t a_handle, double b_classical);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_TEMPLATES_H_ */
