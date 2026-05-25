/* cq_runtime.h — Phase 2 trace-only runtime stub (declarations).
 *
 * Declares the 15 cqrt_* lowering targets used by the IR pass:
 *   - 7 allocators (one per width): cqrt_alloc_i{1,8,16,32,64} +
 *     cqrt_alloc_f{32,64}. Each takes an initial classical value and
 *     returns a fresh monotonically-increasing handle.
 *   - 7 measure ops (one per width): cqrt_measure_i{1,8,16,32,64} +
 *     cqrt_measure_f{32,64}. Each takes a handle and returns a value
 *     of the matching width (always 0 in Phase 2 — the runtime is
 *     trace-only, no simulation).
 *   - cqrt_free(handle): width-irrelevant lifetime hook; declared
 *     but unused in Phase 2 (reserved for later lifetime work).
 *
 * Plus the internal helper `cqrt_alloc_handle`, which is NOT one of
 * the 15 PRD-pinned symbols but is retained so templates (cq_templates)
 * can keep handle numbering globally monotonic with libcq_runtime.
 *
 * Width-only ABI: the runtime sees widths, not signedness. So
 * `signed char` and `unsigned char` both lower to `cqrt_alloc_i8`;
 * signedness is implicit in the LLVM opcode at the call site, not in
 * the runtime symbol. This is intentionally asymmetric with cq_mid.h
 * (which DOES carry signedness because the rewriter cares). See
 * PRD §"Stub libcq_runtime" (Width unification at the runtime ABI).
 *
 * Trace format (per call):
 *     <symbol>(<arg1>[, <arg2>...]) -> <return>
 * (or "<symbol>(<args>)" for cqrt_free, which has no return value).
 * Handles are printed as h<N>, N starting at 0. Bodies for the 12
 * new per-width symbols land in M06; existing 3 bodies (i32 alloc,
 * i32 measure, free) and the cqrt_alloc_handle helper body are
 * unchanged from Phase 1.
 *
 * Front-end intrinsics (cq_init_*, cq_measure_*) carry the
 * signedness-bearing suffix (e.g. _si32); the IR pass bridges
 * frontend signedness suffix → runtime width-only suffix.
 *
 * Spec: phases/phase2/PRD.md §"Stub libcq_runtime";
 *       phases/phase2/PLAN.md §4.4.
 */
#ifndef CQ_RUNTIME_H_
#define CQ_RUNTIME_H_

#include <stdint.h>

/* `bool` is a macro for `_Bool` in C11 via <stdbool.h>; it is a native
 * keyword in C++. Including <stdbool.h> keeps the `bool` spellings
 * below valid in both C TUs (the IR-pass output, the .c bodies in M06)
 * and the C++ unit-test consumer (tests/unit/test_cq_runtime_compiles).
 * The PRD spells the parameter type `_Bool`; `bool` is the equivalent
 * spelling once <stdbool.h> is in scope, and the only one that parses
 * under C++. */
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* -----------------------------------------------------------------
 * Allocation — one per width. Takes an initial classical value;
 * returns a fresh handle. Trace:
 *     "cqrt_alloc_<W>(<value>) -> h<N>"
 * ----------------------------------------------------------------- */
int32_t cqrt_alloc_i1 (bool    value);
int32_t cqrt_alloc_i8 (int8_t  value);   /* serves char / signed char / unsigned char */
int32_t cqrt_alloc_i16(int16_t value);   /* serves short / unsigned short */
int32_t cqrt_alloc_i32(int32_t value);   /* serves int / unsigned int */
int32_t cqrt_alloc_i64(int64_t value);   /* serves (u)long / (u)long long on 64-bit targets */
int32_t cqrt_alloc_f32(float   value);
int32_t cqrt_alloc_f64(double  value);

/* -----------------------------------------------------------------
 * Measurement — one per width. Takes a handle; returns a value of
 * the matching width (always 0 in Phase 2, runtime is trace-only).
 * Trace: "cqrt_measure_<W>(h<handle>) -> <0 in width's format>".
 * ----------------------------------------------------------------- */
bool    cqrt_measure_i1 (int32_t handle);
int8_t  cqrt_measure_i8 (int32_t handle);
int16_t cqrt_measure_i16(int32_t handle);
int32_t cqrt_measure_i32(int32_t handle);
int64_t cqrt_measure_i64(int32_t handle);
float   cqrt_measure_f32(int32_t handle);
double  cqrt_measure_f64(int32_t handle);

/* -----------------------------------------------------------------
 * Free — width-irrelevant (handle-typed only). Declared but unused
 * in Phase 2; reserved for later lifetime work.
 * Trace: "cqrt_free(h<handle>)" (no return-value suffix).
 * ----------------------------------------------------------------- */
void cqrt_free(int32_t handle);

/* Internal helper: returns the next monotonically increasing handle.
 * Used by cqrt_alloc_<W> here and by cq_template_* in the templates
 * module to keep handle numbering globally monotonic. NOT one of the
 * 15 PRD-pinned runtime symbols; not part of the user-facing CQ.h
 * surface either. Retained per PLAN.md §4.4. */
int32_t cqrt_alloc_handle(void);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_RUNTIME_H_ */
