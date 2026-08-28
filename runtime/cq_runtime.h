/* cq_runtime.h — trace-only runtime stub (declarations).
 *
 * Declares the cqrt_* lowering targets used by the IR pass. The base
 * surface is 33 symbols (below); Phase 4 (PRD §2.8) adds the controlled
 * surface — cqrt_rz_<W>_controlled[_inv] (7 widths × 2) and
 * cqrt_x/h/cnot_controlled — each prepending one i32 control-flag
 * handle as argument 0 (PRD §1.2).
 *
 * Phase 7.1 Increment D (FROZEN) adds the half-precision fp width f16 to
 * the rotation-lowering path — cqrt_alloc_f16 / cqrt_measure_f16 /
 * cqrt_ry_f16 / cqrt_rz_f16 (+ the controlled-rz f16 twins for ABI
 * symmetry). There is still NO UNCONTROLLED cqrt_copy_f<W> (no consumer —
 * dead ABI is forbidden), but the CONTROLLED fp copy family
 * cqrt_copy_f{16,32,64,80}_controlled now EXISTS (fp-data-select-PRD,
 * issue kjd1): the old "fp under tainted control is categorically an
 * angle" rule is retired FOR THE TAINTED-`select` MERGE ONLY, where the
 * three-legged angle fence (SelectClassify gate-3 carrier walk + the
 * escape guards + declineTaintedAngle) proves the value is data. Every
 * other fp-under-control path still declines; the uncontrolled copyFn
 * still null-guards on isIntegerTy (WidthDispatch.cpp). The sibling i128
 * int width is deferred (its C ABI shreds __int128 to {i64,i64}; tracked
 * as a pre-freeze follow-up). The 33 base symbols:
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
 * print "cqrt_<op>_<W>(h<handle>, <angle>)" (angle as %a — HEX FLOAT,
 * round-trip exact; bd `ni15` moved every fp trace field off the
 * non-injective 6-digit %f);
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
int32_t cqrt_alloc_f16(_Float16 value);  /* Phase 7.1 Increment D — half-precision */
int32_t cqrt_alloc_f80 (long double value);  /* bd 3c6m.4 — long double (x86-64) */

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
_Float16 cqrt_measure_f16(int32_t handle);  /* Phase 7.1 Increment D */
long double cqrt_measure_f80 (int32_t handle);  /* bd 3c6m.4 — long double (x86-64) */

/* -----------------------------------------------------------------
 * Ry rotation — one per width. Takes a handle + double angle; void.
 * Applies Ry(angle) to each qubit of the register (backend.md §11.3);
 * the lowered theta calls emit these. Trace (no return-value suffix):
 *     "cqrt_ry_<W>(h<handle>, <angle>)"   (angle as %a, hex float).
 * ----------------------------------------------------------------- */
void cqrt_ry_i1 (int32_t handle, double angle);
void cqrt_ry_i8 (int32_t handle, double angle);
void cqrt_ry_i16(int32_t handle, double angle);
void cqrt_ry_i32(int32_t handle, double angle);
void cqrt_ry_i64(int32_t handle, double angle);
void cqrt_ry_f32(int32_t handle, double angle);
void cqrt_ry_f64(int32_t handle, double angle);
void cqrt_ry_f16(int32_t handle, double angle);  /* Phase 7.1 Increment D */
void cqrt_ry_f80 (int32_t handle, double angle);  /* bd 3c6m.4 — long double (x86-64) */

/* -----------------------------------------------------------------
 * Rz rotation — one per width. Same shape as Ry; the lowered phi
 * calls emit these on tainted operands. Trace (no return suffix):
 *     "cqrt_rz_<W>(h<handle>, <angle>)"   (angle as %a, hex float).
 * ----------------------------------------------------------------- */
void cqrt_rz_i1 (int32_t handle, double angle);
void cqrt_rz_i8 (int32_t handle, double angle);
void cqrt_rz_i16(int32_t handle, double angle);
void cqrt_rz_i32(int32_t handle, double angle);
void cqrt_rz_i64(int32_t handle, double angle);
void cqrt_rz_f32(int32_t handle, double angle);
void cqrt_rz_f64(int32_t handle, double angle);
void cqrt_rz_f16(int32_t handle, double angle);  /* Phase 7.1 Increment D */
void cqrt_rz_f80 (int32_t handle, double angle);  /* bd 3c6m.4 — long double (x86-64) */

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
void cqrt_rz_f16_controlled(int32_t ctrl, int32_t handle, double angle);  /* Phase 7.1 Increment D */
void cqrt_rz_f80_controlled (int32_t ctrl, int32_t handle, double angle);  /* bd 3c6m.4 */

void cqrt_rz_i1_controlled_inv (int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i8_controlled_inv (int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i16_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i32_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_i64_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_f32_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_f64_controlled_inv(int32_t ctrl, int32_t handle, double angle);
void cqrt_rz_f16_controlled_inv(int32_t ctrl, int32_t handle, double angle);  /* Phase 7.1 Increment D */
void cqrt_rz_f80_controlled_inv (int32_t ctrl, int32_t handle, double angle);  /* bd 3c6m.4 */

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
 * `cqrt_cnot` and `cqrt_toffoli` ARE pass-emitted too — they are the
 * 3c6m.12 compound-condition FLAG NETWORK, minted in THREE places with one
 * shape (`And` -> a single `cqrt_toffoli(L,R,G)`; `Or` -> `cqrt_cnot(L,G)` +
 * `cqrt_cnot(R,G)` + `cqrt_toffoli(L,R,G)`): `SelectMergeEmit.cpp` for the 4.4
 * tainted-`select` merge (NO clone involved — the one a PredMux-flattened body
 * hits), `Specialization.cpp` for a clone's controlled-return mux, and
 * `BreakReversePlay.cpp` for the 7.4 break reverse-play. `EmitInverse` re-emits
 * each verbatim as its own adjoint since both are involutions. ONLY
 * `cqrt_h` is still declared + defined but unemitted (reserved for
 * Phase 8 / 11). (Corrected by the bd oudq Rule-13 round: these
 * comments are the primary written source for the gates' semantics, and
 * a reviewer modelling a trace was reading "unexercised" for two gates
 * that appear 260 times in a single committed golden.)
 * Trace (no return-value suffix): args printed as h<N>, e.g.
 *     "cqrt_x(h<q>)", "cqrt_cnot(h<ctrl>, h<tgt>)".
 * ----------------------------------------------------------------- */
void cqrt_x      (int32_t q);
void cqrt_h      (int32_t q);
void cqrt_cnot   (int32_t ctrl, int32_t tgt);
void cqrt_toffoli(int32_t c1, int32_t c2, int32_t tgt);

/* -----------------------------------------------------------------
 * Controlled gate primitives (Phase 4, PRD §2.8).
 * `cqrt_x/h/cnot_controlled` prepend one i32 control-flag handle as
 * argument 0 (PRD §1.2), rounding out the controlled gate surface for
 * Phase-8 completeness. Same no-arrow void trace convention as their
 * uncontrolled twins; the control flag prints as a leading h<N>.
 * ----------------------------------------------------------------- */
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
 * (Rule 8: freeing a superposed source stays cqrt_cswap-only).
 * The 5 INTEGER widths PLUS the 4 fp widths f16/f32/f64/f80 (bd 38t2 —
 * the fp-as-bitpattern memory CELL; designated frozen at the Phase-11
 * gate). The fp uncontrolled twin now HAS a consumer: the fp QRAM cell
 * copy-out (`emitCopyOutIfDirectMeasure`, QramLowering) for a
 * direct-sole-measure fp `arr[q]` load, exactly as the integer copy
 * serves the integer cell copy-out — so it is NOT dead ABI. Storing a
 * theta/phi-derived fp value into a memory cell is faithful reversible
 * QRAM (a CNOT-copy of the fp BIT PATTERN preserves the phase in the
 * JOINT amplitude; only the value's local reduced state goes mixed =
 * entanglement, not the Rule-7 dephasing — bd
 * [38t2-fp-cell-commits-to-basis-sound]); the angle fence
 * (declineTaintedAngle) still declines any fp cell value used as a
 * rotation arg-1 angle. The §3 tripwires re-audited for 38t2:
 * ChainWalk's isCopyOutSink `starts_with("cqrt_copy_")` prefix already
 * admits a 2-arg fp copy; LoopLowering's copyFn > 64 fence is
 * fp-orthogonal (`fadd` never reaches the integer in-place rail path).
 * Same no-arrow void trace convention as cqrt_cswap; both handle args
 * print as h<N>:
 *     "cqrt_copy_<W>(h<src>, h<dst>)".
 * ----------------------------------------------------------------- */
void cqrt_copy_i1 (int32_t src, int32_t dst);
void cqrt_copy_i8 (int32_t src, int32_t dst);
void cqrt_copy_i16(int32_t src, int32_t dst);
void cqrt_copy_i32(int32_t src, int32_t dst);
void cqrt_copy_i64(int32_t src, int32_t dst);
void cqrt_copy_f16(int32_t src, int32_t dst);   /* bd 38t2 — fp cell copy-out */
void cqrt_copy_f32(int32_t src, int32_t dst);
void cqrt_copy_f64(int32_t src, int32_t dst);
void cqrt_copy_f80(int32_t src, int32_t dst);

/* -----------------------------------------------------------------
 * Controlled reversible basis copy (Phase 4.4, PRD Part IV §16.3 — the
 * tainted-`select` controlled-XOR copy merge) — `cqrt_copy_<W>_controlled
 * (ctrl, src, dst)` performs the transversal-CNOT basis copy of src into
 * the |0> dst rail iff the i32 control flag `ctrl` is set, leaving dst
 * |0> when ctrl is 0. The control flag is PREPENDED as argument 0 (the
 * control-flag-as-arg-0 invariant, ControlledSymbols.h:7-10), so `src`
 * is arg 1 and `dst` arg 2. The select-merge emitter (`SelectMergeEmit`,
 * Phase 4.4) fires `copy(f, true, out)` then, X-bracketed on ¬f,
 * `copy(f, false, out)` to mux the active operand into the fresh |0>
 * result rail — NO rail, NO route, NO cswap. Like its uncontrolled
 * sibling it copies a computational-basis *label*, not a state (WRONG
 * for any phase/superposition carrier — Rule 7), it NEVER frees,
 * consumes, or disentangles its source (Rule 8), and a controlled-CNOT
 * is an involution, so there is NO cqrt_copy_<W>_controlled_inv twin
 * (its inverse is re-emission of the same call — the cqrt_x class).
 * The 5 integer widths PLUS the 4 fp widths f16/f32/f64/f80
 * (fp-data-select-PRD, issue kjd1 — Option B, designated frozen at the
 * Phase-11 gate): fp-DATA is legitimate for the tainted-`select` merge
 * because the three-legged angle fence (SelectClassify gate-3 carrier
 * walk + the escape guards + declineTaintedAngle) proves the value is
 * data — a theta-derived fp value is a real-amplitude basis
 * superposition of fp BIT PATTERNS, and the CNOT copies that basis
 * label faithfully (bits are bits; handles are i32, Rule 15). The fp
 * twins are minted ONLY by the select-local copyControlledFpFn; every
 * other fp-under-control path (switch, br-diamond value arms, the 6.5
 * classical-call arm, IOSink, AbortPark, QRAM) still declines fp. No
 * fp128 (no sound c_type on this x86-64 build) and no fp UNCONTROLLED
 * copy (no consumer). Same no-arrow void trace convention as
 * cqrt_cswap; all three handle args print as h<N>:
 *     "cqrt_copy_<W>_controlled(h<ctrl>, h<src>, h<dst>)".
 * ----------------------------------------------------------------- */
void cqrt_copy_i1_controlled (int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_i8_controlled (int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_i16_controlled(int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_i32_controlled(int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_i64_controlled(int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_f16_controlled(int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_f32_controlled(int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_f64_controlled(int32_t ctrl, int32_t src, int32_t dst);
void cqrt_copy_f80_controlled(int32_t ctrl, int32_t src, int32_t dst);

/* -----------------------------------------------------------------
 * In-place reversible arithmetic — immediate operand (issue dtzb,
 * the missing arithmetic-STRATEGY axis; Bennett.jl's in-place Cuccaro
 * adder, src/adder.jl: (a,b)->(a,a+b) with b OVERWRITTEN). UNLIKE the
 * out-of-place `cq_template_<op>_<W>_hl(q, c) -> FRESH handle` family
 * (which mints a new rail per call and so cannot be rolled-reverse-
 * played in a loop — the X1 cross-iteration dirty rail), these MUTATE
 * the rail register `h` IN PLACE by a CLASSICAL immediate `imm`:
 *     cqrt_addc_<W>:  h := (h + imm) mod 2^W      (inverse: imm -> -imm)
 *     cqrt_xorc_<W>:  h := h ^ imm                (self-inverse)
 * Void, one handle (+ the iW immediate) — the SAME in-place-gate
 * category as cqrt_rz / cqrt_x (NOT a fresh-rail data template, so NO
 * out arg, NO `_unc`/`_inv` twin: EmitInverse re-emits xorc as-is and
 * addc with a negated immediate, exactly the cqrt_x-involution /
 * cqrt_ry-negate adjoint patterns). TWO EMITTERS, and neither one is
 * new ABI (bd test_C_libtooling-6uqc, M-C Increment 2a, widened the
 * second into existence):
 *   (1) a recognized loop-carried rail SELF-UPDATE `q = q op c` whose
 *       old `q` is dead through the cycle (LoopLowering.cpp, issue dtzb);
 *   (2) a STRAIGHT-LINE reassignment `q = q + c` whose PARENT HANDLE HAS
 *       NO DATA USE AFTER THE OP (ArithLowering.cpp,
 *       `classifyInPlaceReassignment`). Out of place, that add mints a
 *       fresh rail and leaves the parent standing as a live basis RECORD
 *       of the wire, which dephases any later non-diagonal gate on it
 *       (bd test_C_libtooling-nepx). Note the batch: `add` only so far;
 *       `sub`/`xor` are later batches.
 * A straight-line value op whose parent is still LIVE stays OUT-OF-PLACE,
 * and so does one inside a Phase-6 Bennett clone body (the wrap's forward
 * stream is built by scanning for rail-minting templates, and a void gate
 * is not one). The handle is i32 for every width
 * (Rule 15); `imm` carries the logical width. INTEGER widths only.
 * Trace (handle as h<N>, immediate as a decimal literal):
 *     "cqrt_addc_<W>(h<h>, <imm>)" / "cqrt_xorc_<W>(h<h>, <imm>)".
 * ----------------------------------------------------------------- */
void cqrt_addc_i1 (int32_t h, bool    imm);
void cqrt_addc_i8 (int32_t h, int8_t  imm);
void cqrt_addc_i16(int32_t h, int16_t imm);
void cqrt_addc_i32(int32_t h, int32_t imm);
void cqrt_addc_i64(int32_t h, int64_t imm);
void cqrt_xorc_i1 (int32_t h, bool    imm);
void cqrt_xorc_i8 (int32_t h, int8_t  imm);
void cqrt_xorc_i16(int32_t h, int16_t imm);
void cqrt_xorc_i32(int32_t h, int32_t imm);
void cqrt_xorc_i64(int32_t h, int64_t imm);

/* -----------------------------------------------------------------
 * Reversible I/O output tape (Phase 7.6, PRD-7.6 §2.8 — FROZEN core
 * ABI, hand-written here, NOT a `cq_template_*` generated symbol).
 * The coherent replacement for a print-site measurement (Rule 5): a
 * tainted `printf`/`putchar` integer-scalar argument is APPENDED to an
 * output tape as a fresh |0> output rail that is KEPT — never freed,
 * never uncomputed (the Bennett output tape). The measurement is
 * DEFERRED to tape inspection (a backend concern), so the user's
 * register stays coherent.
 *
 *   cqrt_tape_alloc() -> tape
 *       Register a tape; the backend allocates the physical tape and
 *       returns its handle — a CLASSICAL resource token (like a file
 *       descriptor), NOT a qubit and NOT tainted, so the uncompute
 *       spine ignores it. Width-agnostic (a tape holds mixed-width
 *       entries, e.g. `printf("%d%c")`) — ONE symbol. The handle is
 *       drawn from the same monotonic `cqrt_alloc_handle()` counter as
 *       every qubit handle but PRINTS with a `t` prefix to distinguish
 *       a tape from a rail.
 *
 *   cqrt_tape_write_<W>(tape, src) -> out
 *       APPEND `src` to `tape` as a fresh |0> output rail (a CNOT-class
 *       basis copy — `src` is PRESERVED, so `src`'s own lineage still
 *       uncomputes normally through the Phase-5 spine; only the kept
 *       `out` rail is special). The backend owns the append cursor, so
 *       there is NO per-write index. Returns the new kept output-rail
 *       handle. The 5 INTEGER widths only ({i1,i8,i16,i32,i64}, the
 *       `widthHasReversibleCopy` set): an fp `%f` arg in a rail is the
 *       f64/angle miscompile family, and there is no `cqrt_tape_write_
 *       i128` — both DECLINE in the IR pass, never minting a phantom.
 *       Distinct from `cqrt_copy_<W>` so the backend can always tell an
 *       output qubit from a scratch copy AND so the uncompute spine
 *       recognizes it as SINK-class and never recovers it as a
 *       reversible gate (PRD-7.6 §2.4). Handles are always i32; the
 *       width only selects the symbol name.
 *
 *   cqrt_tape_write_<W>_controlled(ctrl, tape, src) -> out
 *       Tier-0 CONDITIONAL output (`if(q)printf`, Phase 7.6 Increment 2). The
 *       appended entry's CONTENT is committed under the i32 control flag
 *       `ctrl` (PREPENDED as argument 0, the control-flag-as-arg-0 invariant —
 *       mirrors `cqrt_copy_<W>_controlled`); `tape` is arg 1, `src` arg 2. The
 *       entry is ALWAYS appended (tape length is classical/deterministic, so
 *       there is never a superposition over "the tape has N vs N+1 entries") —
 *       only its content is conditional. A controlled-CNOT involution that
 *       preserves `src`; returns the new kept output-rail handle. Same 5
 *       INTEGER widths and the same SINK-class spine treatment as the
 *       uncontrolled write (recognized by the `cqrt_tape_write_` prefix).
 *
 * Trace (the golden contract, PRD-7.6 §2.8): the tape handle prints as
 * `t<N>`, every rail handle (incl. the control flag) as `h<N>`:
 *     "cqrt_tape_alloc() -> t<N>"
 *     "cqrt_tape_write_<W>(t<tape>, h<src>) -> h<out>"
 *     "cqrt_tape_write_<W>_controlled(h<ctrl>, t<tape>, h<src>) -> h<out>".
 * ----------------------------------------------------------------- */
int32_t cqrt_tape_alloc(void);
int32_t cqrt_tape_write_i1 (int32_t tape, int32_t src);
int32_t cqrt_tape_write_i8 (int32_t tape, int32_t src);
int32_t cqrt_tape_write_i16(int32_t tape, int32_t src);
int32_t cqrt_tape_write_i32(int32_t tape, int32_t src);
int32_t cqrt_tape_write_i64(int32_t tape, int32_t src);
int32_t cqrt_tape_write_i1_controlled (int32_t ctrl, int32_t tape, int32_t src);
int32_t cqrt_tape_write_i8_controlled (int32_t ctrl, int32_t tape, int32_t src);
int32_t cqrt_tape_write_i16_controlled(int32_t ctrl, int32_t tape, int32_t src);
int32_t cqrt_tape_write_i32_controlled(int32_t ctrl, int32_t tape, int32_t src);
int32_t cqrt_tape_write_i64_controlled(int32_t ctrl, int32_t tape, int32_t src);

/* -----------------------------------------------------------------
 * QRAM — tainted-index memory (Phase 7.5, PRD-7.5 §2.3 — FROZEN core
 * ABI, hand-written here, NOT a `cq_template_*` generated symbol). The
 * coherent lowering of a dynamic/tainted-index array access `a[i]` (a
 * static index is SROA'd away by clang -O1 and never reaches the pass).
 * STUB-ONLY: the Shadow/MUX-EXCH/QROM gate mechanics live in the
 * (deferred) backend; these stubs record only the (array, index) ABI the
 * backend implements. The strategy choice (Shadow vs MUX vs QROM) is a
 * backend detail and NEVER leaks into these signatures (PRD-7.5 §2.1).
 *
 *   cqrt_qram_alloc_<W>(count) -> arr
 *       Register a KNOWN-SHAPE array of `count` width-`W` cells; the
 *       backend allocates the physical register block and returns the
 *       ARRAY HANDLE — an i32 resource token (like a tape handle: a
 *       classical token, NOT a qubit and NOT tainted, so the uncompute
 *       spine ignores it). The cell CONTENTS are classical metadata
 *       (a const table / a memset-0 initializer), replayed at inspection,
 *       not passed here — only the count (PRD-7.5 §2.6, §2.12). The handle
 *       is drawn from the shared monotonic `cqrt_alloc_handle()` counter
 *       but PRINTS with an `a` prefix to distinguish an array from a rail.
 *
 *   cqrt_qram_load_<W>(arr, idx) -> out
 *       Read the cell at the (quantum) index `idx` into a FRESH i32 value
 *       handle (Toffoli-copy-out — the cell is PRESERVED). An ordinary
 *       reversible data producer: the whole-DAG uncompute spine reverses
 *       a dead loaded value via the `_unc` twin below. The index handle is
 *       ALWAYS i32 (Rule 15; the -O1 `sext …to i64` is stripped). The 5
 *       INTEGER widths only ({i1,i8,i16,i32,i64}, `widthHasReversibleCopy`):
 *       an fp cell is the f64/angle hazard and there is no
 *       `cqrt_qram_load_i128` — both DECLINE in the IR pass, never minting
 *       a phantom.
 *
 *   cqrt_qram_load_<W>_unc(out, arr, idx)
 *       Adjoint of a load: un-copy the dead loaded value `out` back to |0>
 *       using the (preserved) cell at `idx`. Void, in-place on `out`. The
 *       `_unc(out, src…)` slot convention mirrors `cq_template_*_unc`
 *       (out first, then the forward operands in order).
 *
 *   cqrt_qram_store_<W>(arr, idx, val)   (Phase 7.5 Increment 2)
 *       Write the (i32 handle) `val` into the cell at the (quantum) index
 *       `idx`. VOID and IN-PLACE on the arg-0 array handle — structurally
 *       the same shape as `cqrt_rz_<W>` (a void mutation that mints no new
 *       value and keeps the handle live), so the uncompute spine treats it
 *       as an in-place gate on `arr`. The backend stashes the displaced old
 *       cell value on ITS OWN per-store tape (never in the IR or the ABI —
 *       owner decision 1, §2.4); the IR pass owns only the reversal ORDER.
 *       `val` is ALWAYS a handle (a tainted value is its own handle; a
 *       classical store value is materialized into a basis-state handle via
 *       `cqrt_alloc_<W>` so the (arr, idx, val) trace stays all-handles).
 *
 *   cqrt_qram_store_<W>_unc(arr, idx, val)   (Phase 7.5 Increment 2)
 *       Adjoint of a store: the backend POPS its tape, restoring the cell's
 *       old value. SAME args as the forward store (NOT out-first — a store
 *       mints no rail); `_unc` selects pop over push. The spine fires the
 *       `_unc` twins in STRICT reverse program order of the forward stores
 *       to one array (LIFO), so the backend's tape stack pops in push order
 *       (§2.8(ii)). A void mutation on one handle is totally ordered and a
 *       quantum-index store touches every cell, so the stores never commute.
 *
 * Trace (the golden contract, PRD-7.5 §2.3): the array handle prints as
 * `a<N>`, every rail handle as `h<N>`:
 *     "cqrt_qram_alloc_<W>(<count>) -> a<N>"
 *     "cqrt_qram_load_<W>(a<arr>, h<idx>) -> h<out>"
 *     "cqrt_qram_load_<W>_unc(h<out>, a<arr>, h<idx>)"   (void, no arrow).
 *     "cqrt_qram_store_<W>(a<arr>, h<idx>, h<val>)"      (void, no arrow).
 *     "cqrt_qram_store_<W>_unc(a<arr>, h<idx>, h<val>)"  (void, no arrow).
 * ----------------------------------------------------------------- */
int32_t cqrt_qram_alloc_i1 (int32_t count);
int32_t cqrt_qram_alloc_i8 (int32_t count);
int32_t cqrt_qram_alloc_i16(int32_t count);
int32_t cqrt_qram_alloc_i32(int32_t count);
int32_t cqrt_qram_alloc_i64(int32_t count);
int32_t cqrt_qram_alloc_f16(int32_t count);   /* bd 38t2 — fp-as-bitpattern cell */
int32_t cqrt_qram_alloc_f32(int32_t count);
int32_t cqrt_qram_alloc_f64(int32_t count);
int32_t cqrt_qram_alloc_f80(int32_t count);

int32_t cqrt_qram_load_i1 (int32_t arr, int32_t idx);
int32_t cqrt_qram_load_i8 (int32_t arr, int32_t idx);
int32_t cqrt_qram_load_i16(int32_t arr, int32_t idx);
int32_t cqrt_qram_load_i32(int32_t arr, int32_t idx);
int32_t cqrt_qram_load_i64(int32_t arr, int32_t idx);
int32_t cqrt_qram_load_f16(int32_t arr, int32_t idx);   /* bd 38t2 */
int32_t cqrt_qram_load_f32(int32_t arr, int32_t idx);
int32_t cqrt_qram_load_f64(int32_t arr, int32_t idx);
int32_t cqrt_qram_load_f80(int32_t arr, int32_t idx);

void cqrt_qram_load_i1_unc (int32_t out, int32_t arr, int32_t idx);
void cqrt_qram_load_i8_unc (int32_t out, int32_t arr, int32_t idx);
void cqrt_qram_load_i16_unc(int32_t out, int32_t arr, int32_t idx);
void cqrt_qram_load_i32_unc(int32_t out, int32_t arr, int32_t idx);
void cqrt_qram_load_i64_unc(int32_t out, int32_t arr, int32_t idx);
void cqrt_qram_load_f16_unc(int32_t out, int32_t arr, int32_t idx);   /* bd 38t2 */
void cqrt_qram_load_f32_unc(int32_t out, int32_t arr, int32_t idx);
void cqrt_qram_load_f64_unc(int32_t out, int32_t arr, int32_t idx);
void cqrt_qram_load_f80_unc(int32_t out, int32_t arr, int32_t idx);

void cqrt_qram_store_i1 (int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i8 (int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i16(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i32(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i64(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f16(int32_t arr, int32_t idx, int32_t val);   /* bd 38t2 */
void cqrt_qram_store_f32(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f64(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f80(int32_t arr, int32_t idx, int32_t val);

void cqrt_qram_store_i1_unc (int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i8_unc (int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i16_unc(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i32_unc(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i64_unc(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f16_unc(int32_t arr, int32_t idx, int32_t val);   /* bd 38t2 */
void cqrt_qram_store_f32_unc(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f64_unc(int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f80_unc(int32_t arr, int32_t idx, int32_t val);

/* -----------------------------------------------------------------
 * iw81.7 — path-predicate-GUARDED Shadow store (tainted-index memop UNDER
 * tainted control). Same (arr, idx, val) contract as cqrt_qram_store_<W>, with
 * the block path predicate `pred` as arg 0. The backend realizes the Bennett
 * guarded shadow / MUX store (Bennett.jl `emit_shadow_store_guarded!` /
 * `soft_mux_store_guarded_NxW`): each store CNOT lifted to a Toffoli(pred, ...),
 * a NO-OP on cell + tape when pred=0, coherent under a superposed pred. The ABI
 * is STRATEGY-AGNOSTIC (PRD-7.5 §2.4) — the per-store tape stays backend-owned.
 *   cqrt_qram_store_<W>_controlled(pred, arr, idx, val)
 *       Store `val` at `idx` iff `pred` — the genuinely-controlled store the
 *       swap-route mechanism CANNOT express (memory has no per-arm work rail; a
 *       store on the wrong branch is the verify-clean-invisible miscompile).
 *   cqrt_qram_store_<W>_controlled_unc(pred, arr, idx, val)
 *       Adjoint — pops the backend tape ONLY on the branch where the forward
 *       store pushed. A DISTINCT symbol (store is not self-inverse), gated by
 *       the SAME pred, fired in strict LIFO reverse (§2.8(ii)). An ungated /
 *       pred-stripped _unc over-pops the inactive branch (a dephasing silent
 *       miscompile) — the pred rail is kept live through the _unc, THEN stripped.
 * Trace: `pred` is a rail handle → prints `h<pred>`:
 *     "cqrt_qram_store_<W>_controlled(h<pred>, a<arr>, h<idx>, h<val>)"     (void).
 *     "cqrt_qram_store_<W>_controlled_unc(h<pred>, a<arr>, h<idx>, h<val>)" (void).
 * ----------------------------------------------------------------- */
void cqrt_qram_store_i1_controlled (int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i8_controlled (int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i16_controlled(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i32_controlled(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i64_controlled(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f16_controlled(int32_t pred, int32_t arr, int32_t idx, int32_t val);   /* bd 38t2 */
void cqrt_qram_store_f32_controlled(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f64_controlled(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f80_controlled(int32_t pred, int32_t arr, int32_t idx, int32_t val);

void cqrt_qram_store_i1_controlled_unc (int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i8_controlled_unc (int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i16_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i32_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_i64_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f16_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);   /* bd 38t2 */
void cqrt_qram_store_f32_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f64_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_f80_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);

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
