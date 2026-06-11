/* cq_runtime.h — trace-only runtime stub (declarations).
 *
 * Declares the cqrt_* lowering targets used by the IR pass. The base
 * surface is 33 symbols (below); Phase 4 (PRD §2.8) adds the controlled
 * surface — cqrt_rz_<W>_controlled[_inv] (7 widths × 2), cqrt_toffoli_inv,
 * and cqrt_x/h/cnot_controlled — each prepending one i32 control-flag
 * handle as argument 0 (PRD §1.2). The 33 base symbols:
 *   - 7 allocators (one per width): cqrt_alloc_i{1,8,16,32,64} +
 *     cqrt_alloc_f{32,64}. Each takes an initial classical value and
 *     returns a fresh monotonically-increasing handle.
 *   - 7 measure ops (one per width): cqrt_measure_i{1,8,16,32,64} +
 *     cqrt_measure_f{32,64}. Each takes a handle and returns a value
 *     of the matching width (always 0 — the runtime is
 *     trace-only, no simulation).
 *   - 7 Ry rotations (one per width): cqrt_ry_i{1,8,16,32,64} +
 *     cqrt_ry_f{32,64}. Each takes a handle + double angle, returns
 *     void; the lowered theta calls (backend.md §11.3) emit these.
 *   - 7 Rz rotations (one per width): cqrt_rz_i{1,8,16,32,64} +
 *     cqrt_rz_f{32,64}. Same shape as Ry; the lowered phi calls emit
 *     these on tainted operands.
 *   - 4 gate primitives (backend.md §11.4): cqrt_x, cqrt_h,
 *     cqrt_cnot, cqrt_toffoli — handle-typed, void, for internal use
 *     by the template library and Phase 11 passes. Declared + defined
 *     this phase but NOT yet emitted by the IR pass (Phase 8).
 *   - cqrt_free(handle): width-irrelevant lifetime hook; declared
 *     but unused (reserved for later lifetime work).
 *
 * Plus the internal helper `cqrt_alloc_handle`, which is NOT one of
 * the 33 PRD-pinned symbols but is retained so templates (cq_templates)
 * can keep handle numbering globally monotonic with libcq_runtime.
 *
 * Width-only ABI: the runtime sees widths, not signedness. So
 * `signed char` and `unsigned char` both lower to `cqrt_alloc_i8`;
 * signedness is implicit in the LLVM opcode at the call site, not in
 * the runtime symbol. This is intentionally asymmetric with the
 * front-end suffix convention (docs/frontend.md §3.1; include/CQ.h),
 * which DOES carry signedness because the rewriter cares. See
 * PRD §"Stub libcq_runtime" (Width unification at the runtime ABI).
 *
 * Trace format (per call):
 *     <symbol>(<arg1>[, <arg2>...]) -> <return>
 * (or "<symbol>(<args>)" for the void ops — cqrt_free, the ry/rz
 * rotations, and the gate primitives — which have no return value).
 * Handles are printed as h<N>, N starting at 0. The ry/rz rotations
 * print "cqrt_<op>_<W>(h<handle>, <angle>)" (angle as %f, 6 digits);
 * the gate primitives print their handle args only. None of the
 * void ops mint a handle, so the monotonic counter never advances on
 * them.
 *
 * Front-end intrinsics (cq_init_*, cq_measure_*) carry the
 * signedness-bearing suffix (e.g. _si32); the IR pass bridges
 * frontend signedness suffix → runtime width-only suffix.
 */
#ifndef CQ_RUNTIME_H_
#define CQ_RUNTIME_H_

#include <stdint.h>

/* `bool` is a macro for `_Bool` in C11 via <stdbool.h>; it is a native
 * keyword in C++. Including <stdbool.h> keeps the `bool` spellings
 * below valid in both C TUs (the IR-pass output, the .c bodies)
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
 * the matching width (always 0, runtime is trace-only).
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
 * Ry rotation — one per width. Takes a handle + double angle; void.
 * Applies Ry(angle) to each qubit of the register (backend.md §11.3);
 * the lowered theta calls emit these. Trace (no return-value suffix):
 *     "cqrt_ry_<W>(h<handle>, <angle>)"   (angle as %f, 6 digits).
 * ----------------------------------------------------------------- */
void cqrt_ry_i1 (int32_t handle, double angle);
void cqrt_ry_i8 (int32_t handle, double angle);
void cqrt_ry_i16(int32_t handle, double angle);
void cqrt_ry_i32(int32_t handle, double angle);
void cqrt_ry_i64(int32_t handle, double angle);
void cqrt_ry_f32(int32_t handle, double angle);
void cqrt_ry_f64(int32_t handle, double angle);

/* -----------------------------------------------------------------
 * Rz rotation — one per width. Same shape as Ry; the lowered phi
 * calls emit these on tainted operands. Trace (no return suffix):
 *     "cqrt_rz_<W>(h<handle>, <angle>)"   (angle as %f, 6 digits).
 * ----------------------------------------------------------------- */
void cqrt_rz_i1 (int32_t handle, double angle);
void cqrt_rz_i8 (int32_t handle, double angle);
void cqrt_rz_i16(int32_t handle, double angle);
void cqrt_rz_i32(int32_t handle, double angle);
void cqrt_rz_i64(int32_t handle, double angle);
void cqrt_rz_f32(int32_t handle, double angle);
void cqrt_rz_f64(int32_t handle, double angle);

/* -----------------------------------------------------------------
 * Controlled Rz rotation (Phase 4, PRD §2.8) — the controlled form of
 * the lowered cq_phi gate body. Prepends a single i32 control-flag
 * handle as argument 0 (PRD §1.2: one control wire per op); the
 * `_controlled_inv` form is the region-inversion variant (Phase 5/7
 * uncompute, which cannot reuse plain rz because the control wire must
 * thread through). 7 widths × {controlled, controlled_inv}. Trace (no
 * return-value suffix), control flag printed as a leading h<N>:
 *     "cqrt_rz_<W>_controlled(h<ctrl>, h<handle>, <angle>)".
 * Declared + defined this phase; the IR pass begins emitting the
 * controlled rz in WP3 (substitution of in-shadow gate bodies).
 * ----------------------------------------------------------------- */
void cqrt_rz_i1_controlled (int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i8_controlled (int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i16_controlled(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i32_controlled(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i64_controlled(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_f32_controlled(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_f64_controlled(int32_t ctrl, int32_t handle, double angle);

void cqrt_rz_i1_controlled_inv (int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i8_controlled_inv (int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i16_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i32_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i64_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_f32_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_f64_controlled_inv(int32_t ctrl, int32_t handle, double angle);

/* -----------------------------------------------------------------
 * Controlled Ry inverse (npu.6) — the controlled inverse of the
 * Ry-prep rotation (`cqrt_ry_<W>`, the lowered cq_theta). Same
 * `(i32 ctrl, i32 handle, double angle)` shape as the controlled Rz
 * above. Emitted ONLY by the gated-switch MUX-EXCH lowering to
 * UNCOMPUTE a non-selected source's single-Ry prep back to |0> on the
 * branches where `cqrt_cswap` did NOT move it: `Ry†(angle)` controlled
 * on ¬f_q (the source was prepared but not selected, so it stays
 * entangled with the scrutinee unless its prep is reversed — Bennett /
 * QROM disentangle). There is NO plain `cqrt_ry_<W>_controlled` twin:
 * the prep itself is unconditional, only its inverse is controlled. 7
 * widths. Trace mirrors the controlled rz:
 *     "cqrt_ry_<W>_controlled_inv(h<ctrl>, h<handle>, <angle>)".
 * ----------------------------------------------------------------- */
void cqrt_ry_i1_controlled_inv (int32_t ctrl, int32_t handle, double angle);
void cqrt_ry_i8_controlled_inv (int32_t ctrl, int32_t handle, double angle);
void cqrt_ry_i16_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_ry_i32_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_ry_i64_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_ry_f32_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_ry_f64_controlled_inv(int32_t ctrl, int32_t handle, double angle);

/* -----------------------------------------------------------------
 * Gate primitives (backend.md §11.4) — handle-typed, void. `cqrt_x` IS
 * pass-emitted since Phase 4.1: the swap-route emitter brackets a
 * ¬flag (else / false-successor) arm in a self-inverse `cqrt_x(flag)`
 * pair so the enclosed `cqrt_cswap` routes on the negated flag. The
 * other three (`cqrt_h`/`cqrt_cnot`/`cqrt_toffoli`) are declared +
 * defined but not yet emitted (reserved for Phase 8 / 11 passes).
 * Trace (no return-value suffix): args printed as h<N>, e.g.
 *     "cqrt_x(h<q>)", "cqrt_cnot(h<ctrl>, h<tgt>)".
 * ----------------------------------------------------------------- */
void cqrt_x      (int32_t q);
void cqrt_h      (int32_t q);
void cqrt_cnot   (int32_t ctrl, int32_t tgt);
void cqrt_toffoli(int32_t c1, int32_t c2, int32_t tgt);

/* -----------------------------------------------------------------
 * Controlled gate primitives + Toffoli inverse (Phase 4, PRD §2.8).
 * `cqrt_toffoli_inv` uncomputes a flag conjunction (the && / || / nest
 * bracket, PRD §2.5/§2.7); `cqrt_toffoli` itself already exists above.
 * `cqrt_x/h/cnot_controlled` prepend one i32 control-flag handle as
 * argument 0 (PRD §1.2), rounding out the controlled gate surface for
 * Phase-8 completeness. Same no-arrow void trace convention as their
 * uncontrolled twins; the control flag prints as a leading h<N>.
 * ----------------------------------------------------------------- */
void cqrt_toffoli_inv (int32_t c1, int32_t c2, int32_t tgt);
void cqrt_x_controlled   (int32_t ctrl, int32_t q);
void cqrt_h_controlled   (int32_t ctrl, int32_t q);
void cqrt_cnot_controlled(int32_t ctrl, int32_t target_ctrl, int32_t tgt);

/* -----------------------------------------------------------------
 * Controlled-SWAP / Fredkin (npu.4) — `cqrt_cswap(i32 ctrl, i32 a,
 * i32 b)` swaps registers a and b iff the i32 control flag is set.
 * It is pass-emitted: the RSSA swap-route control emitter
 * (`SwapRouteEmit`, Phase 4) routes a tainted-`br` arm's operand into a
 * |0> work rail with `cqrt_cswap(flag, value, rail)` and routes the
 * active result back with the adjoint split — `cqrt_cswap(flag, value,
 * railResult)` — the tainted `phi` being the inverse of the `br` on the
 * same live flag (SWAP is an involution, so the route-back IS the
 * adjoint helper call). Phase 4.1 routes phase arms; 4.2 routes the
 * value-register of a method-B value arm (and brackets the ¬flag arm in
 * a `cqrt_x` pair, see the gate primitives above). SWAP is an
 * involution, so the controlled-SWAP is its own inverse — no `_inv`
 * twin. (The deleted controlled-op generation's gated-switch MUX-EXCH
 * use is gone with commit 7cde677; routing is the only caller now.)
 * Same no-arrow void trace convention; all three args print as h<N>.
 * ----------------------------------------------------------------- */
void cqrt_cswap(int32_t ctrl, int32_t a, int32_t b);

/* -----------------------------------------------------------------
 * Reversible basis copy (Phase 4.2, PRD Part II §8.1 — the design's
 * only new ABI) — `cqrt_copy_<W>(src, dst)` is the keep-sources-live
 * transversal-CNOT basis copy |x>_src |0>_dst -> |x>_src |x>_dst.
 * Precondition: dst is a fresh |0> register (the emitter allocates it
 * immediately before the copy). It copies a computational-basis
 * *label*, not a state — WRONG for any phase/superposition carrier
 * (Rule 7: a CNOT copy of an Rz/Ry answer dephases it; method-B is
 * value-arm only). An involution — applying it twice returns dst to
 * |0> — so there is NO cqrt_copy_<W>_inv twin (same class as cqrt_x /
 * cqrt_cswap). It NEVER frees, consumes, or disentangles its source
 * (Rule 8: freeing a superposed source stays cqrt_cswap-only).
 * The 5 INTEGER widths only — an FP merge phi under tainted control
 * is categorically an angle, never data (the f64 miscompile family),
 * so no f32/f64 twins exist. Emitted by the IR pass as the copy-out
 * step of the 4.2 value-arm (method-B) swap-route lowering. Same
 * no-arrow void trace convention as cqrt_cswap; both handle args
 * print as h<N>:
 *     "cqrt_copy_<W>(h<src>, h<dst>)".
 * ----------------------------------------------------------------- */
void cqrt_copy_i1 (int32_t src, int32_t dst);
void cqrt_copy_i8 (int32_t src, int32_t dst);
void cqrt_copy_i16(int32_t src, int32_t dst);
void cqrt_copy_i32(int32_t src, int32_t dst);
void cqrt_copy_i64(int32_t src, int32_t dst);

/* -----------------------------------------------------------------
 * Free — width-irrelevant (handle-typed only). Declared but unused;
 * reserved for later lifetime work.
 * Trace: "cqrt_free(h<handle>)" (no return-value suffix).
 * ----------------------------------------------------------------- */
void cqrt_free(int32_t handle);

/* Internal helper: returns the next monotonically increasing handle.
 * Used by cqrt_alloc_<W> here and by cq_template_* in the templates
 * module to keep handle numbering globally monotonic. NOT one of the
 * 33 PRD-pinned runtime symbols; not part of the user-facing CQ.h
 * surface either. */
int32_t cqrt_alloc_handle(void);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_RUNTIME_H_ */
