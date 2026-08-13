; lowering_uncompute_lshr_i32_lh.ll — witness restoration for the `_lh` logical
; right-shift ADJOINT (bd `gowy`).
;
; PROVENANCE (verified, not remembered). Commit dbab515 (`tkju`) DE-VENDORED 52
; `tests/e2e/slice_libm_real_*.c` IN PLACE: it stripped the fictional openlibm
; SOFTWARE bodies those slices had vendored for Rule-18 HARDWARE keeps and
; regenerated their goldens. It DELETED NOTHING — `git show --name-status dbab515`
; is 1 A + 75 M with ZERO D, and `tests/e2e` holds the same 249 `.c` slices before
; and after. What vanished was TRACE COVERAGE, not files: 21 `.expected.log` files
; were regenerated, and the `cq_template_*` lines that were 20 symbols' only witness
; went with the bit-twiddle ladders that used to emit them. For THIS symbol the loss
; is exact and re-checkable: `cq_template_lshr_i32_lh_unc` appears 21 times in
; `tests/e2e/slice_libm_real_coshl.expected.log` at dbab515^ and 0 times at dbab515
; (that slice is alive and green; it simply no longer compiles a software shift
; ladder). 14 of the 20 orphans are `_unc`/`_inv` adjoint twins, i.e. the uncompute
; spine, which is exactly where this project's verify-clean silent miscompiles live.
; `cq_template_lshr_i32_lh_unc` was left existing only in the generated runtime
; (`runtime/cq_templates.h:1427`, `cq_templates.c:9109`) with NO witness anywhere:
; not an e2e golden, not a lit fixture. This fixture is that witness, at ir-pass
; cost. (The FORWARD `_lh` is still covered by surviving `slice_libm_real_*`
; goldens — the asymmetry is real: forward covered, adjoint orphaned.)
;
; No accept-predicate is added here, so a positive fixture suffices (Rule 12): the
; `_lh` shape is already accepted — what was lost is the PROOF that it stays right.
;
; THE PHYSICS BEING PINNED — `lshr` is NON-COMMUTATIVE. Unlike `add`, the operands
; of `100 >> q` cannot be normalized into the `_hl` shape, so `_lh` is a genuinely
; distinct symbol with a genuinely distinct unitary. The void `_unc` emitter is
; shape-agnostic (EmitInverse.cpp): it PREPENDS `out` and then copies the forward
; operands in their ORIGINAL order — DD-3 slot mapping. So the forward
; `cq_template_lshr_i32_lh(lit, h)` must adjoint to
; `cq_template_lshr_i32_lh_unc(out, lit, h)`: the classical literal STAYS in forward
; slot 0, the handle STAYS in forward slot 1, `out` is prepended and nothing else
; moves. TWO distinct verify-clean miscompiles are locked out here, and they are NOT
; the same bug:
;   * WRONG SYMBOL — emitting the `_hl` sibling (`cq_template_lshr_i32_hl(h, 100)`)
;     embeds `q >> 100` instead of `100 >> q`: a different — and for i32, degenerate
;     — permutation on the same rails.
;   * SWAPPED SLOTS within `_lh` — the frozen ABI is `void
;     cq_template_lshr_i32_lh_unc(int32_t out_handle, int32_t a_classical,
;     int32_t b_handle)`, so `_lh_unc(out, h, 100)` is worse than an arithmetic
;     mix-up: it feeds the RAIL ID of `%h` into the CLASSICAL-value slot and the
;     literal 100 into the HANDLE slot, addressing a rail `h100` that was never
;     allocated (the runtime prints that slot as `h%d`).
; `opt -verify` sees neither, because every slot is `i32` and both calls are
; perfectly well-typed. This is the direct `lshr` analogue of the `sub_i32_lh` slot
; lock in lowering_uncompute_lh_slot.ll; the `_hl` sibling shape (`q >> 3`) puts the
; handle first and is a different symbol entirely — the two must never alias.
;
; The reversal itself is the whole-DAG LIFO spine, leaf-first: the dead terminal
; `%d` is the leaf, so its adjoint runs FIRST, while the root rail `%h` is STILL
; LIVE and not yet un-rotated. That liveness is load-bearing, not incidental — the
; embedded shift `|a,b,c⟩ → |a,b, c ⊕ (a>>b)⟩` is self-inverse only if the `_unc`
; can RE-READ the same source `b` it read on the forward pass; reversing in any
; other order would XOR back a value computed from an already-restored rail.
;
; THE TWO FREES ARE LICENSED BY DIFFERENT FACTS, and the distinction is real:
;   * the DERIVED rail `%d` genuinely reaches |0⟩ — its own `_unc` XORs the value
;     back out in place, which is what licenses `cqrt_free(%d)` on the very NEXT
;     line (Rule 6: free only a proven-|0⟩ rail; a free placed BEFORE the `_unc`
;     would be a hidden measurement collapsing `q`);
;   * the ROOT `%h` was never |0⟩ to begin with — `cqrt_alloc_i32(%x)` initialises
;     it to the alloc-time CLASSICAL BASIS state |x⟩ and `Ry(-θ)` restores THAT
;     state, not |0⟩. What licenses `cqrt_free(%h)` is that it is provably
;     DISENTANGLED and in a known classical state.
;
; The adjoint MUST be the VOID `_unc`, never the fresh-minting `_inv`: `_inv`
; returns a NEW handle (allocating another rail) instead of driving the existing
; out rail to |0⟩ in place, so an `_inv` here would leave the forward rail dirty and
; still entangled — the CHECK-NOT below is what keeps that substitution out.
;
; ADJACENCY IS PINNED WITH CHECK-NEXT, NOT PLAIN CHECK. Ordered plain CHECK
; directives admit arbitrary text between matches, so an all-plain-CHECK version of
; this fixture stays GREEN under a mutant that splices `call void @cqrt_x(i32 %d)`
; between the `_unc` and its `cqrt_free` — re-dirtying the rail the adjoint had just
; zeroed and turning that free into a hidden measurement (Rule 6). Verified
; empirically against the real lowered output. The same hole admits a
; `cqrt_free(%h)` spliced in AHEAD of the `_unc`, i.e. an adjoint reading a rail the
; hardware has already reset. The whole lowered body IS contiguous in the real
; output, so every line below is CHECK-NEXT and no such splice survives. (A scoped
; CHECK-NOT on `cqrt_free` between the forward and the `_unc` would add nothing
; here: CHECK-NEXT already forbids ANY intervening line, so that NOT could never
; fire. Note also that a directive keyword must never appear with its colon in this
; prose — FileCheck would parse it as a real directive.)
;
; `q = cq_theta; d = 100 >> q` — a dead single-register `_lh` terminal.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
;
; Root rail allocated from the DATA operand %x (never from the angle — Rule 3),
; then rotated by the arg-1 classical angle; then the forward `_lh` shift with the
; literal at slot 0 and the handle at slot 1:
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_lshr_i32_lh(i32 100, i32 %[[H]])
; Reversed adjoint: void `_unc(out=%d, lit=100, src=%h)` — DD-3 slots preserved
; verbatim, reading the still-live root %h; then the now-proven-|0> out rail is
; freed IMMEDIATELY (nothing may re-dirty it in between); then the root is
; un-rotated back to its alloc-time basis state and released. Handle identity is
; captured, not merely symbol presence, and all handles are i32 (Rule 15).
; CHECK-NEXT: call void @cq_template_lshr_i32_lh_unc(i32 %[[D]], i32 100, i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H]])
;
; No fresh-minting adjoint, no wrong-symbol `_hl` alias, and the intrinsic is gone
; (the swapped-slot failure mode is pinned POSITIVELY by the exact operand list
; above; these guards catch the wrong-symbol and stale-intrinsic ones). These are
; non-vacuous despite scanning only [last match -> EOF]: the lowered module's
; declare block mirrors exactly the emitted symbol set, so a spurious `_inv`/`_hl`
; call drags its own `declare` into that tail region — and `@cq_theta_si32` really
; is erased by the pass, so its absence is a genuine witness of intrinsic removal.
; CHECK-NOT: cq_template_lshr_i32_lh_inv
; CHECK-NOT: cq_template_lshr_i32_hl
; CHECK-NOT: cq_theta_
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = lshr i32 100, %q                          ; lit >> q => _lh, dead terminal
  ret void
}
