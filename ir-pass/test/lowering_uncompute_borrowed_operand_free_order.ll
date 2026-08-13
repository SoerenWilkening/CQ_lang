; lowering_uncompute_borrowed_operand_free_order.ll — ACCEPT (Phase 5). A rail's
; `cqrt_free` must follow the adjoint of every gate that READS it, not just of the
; gates that WRITE it (bd test_C_libtooling-uow0 Rule-13 round).
;
; THE INVARIANT. `emitDagReversal` frees each rail right after the adjoint of the
; earliest forward gate that TOUCHES it, because in reverse order that adjoint is
; the LAST of the rail's reverse-touches. "Touches" has to mean READS-OR-WRITES. It
; used to mean writes only (`railOf`), and a gate that merely BORROWS a rail — a
; QRAM store's flag / idx / val — still READS it in its `_unc`. When a rail's first
; WRITE comes after a gate that READS it, keying on writes alone puts the free ahead
; of that gate's `_unc`.
;
; BOTH RAILS BELOW ARE THAT SHAPE, and they are two independent instances:
;   * %z is the arg-0 FLAG of the GUARDED store, whose arg-1 array is the rail the
;     gate writes. This instance was INTRODUCED by the bd uow0 `railOf` fix and
;     found by its own Rule-13 round: before uow0, `railOf` mis-named the flag as
;     the store's rail, which accidentally made the store count as a write of %z and
;     papered the hole over. Correcting the attribution exposed it.
;   * %v is the arg-2 VALUE of the PLAIN store, which neither `railOf` spelling ever
;     claimed. That instance PRE-DATES uow0 and is present at HEAD 1ec8c45 —
;     MEASURED: the pre-uow0 pass emits `cqrt_free(%v)` then
;     `cqrt_qram_store_i32_unc(..., %v)`, and stage 2b reports
;     `VIOLATION F2-use-after-free`. So this is not a fix for a self-inflicted
;     regression; the regression is one instance of a hole that was already there.
;
; INVISIBLE TO `opt`: rc=0 and `opt -passes=verify` clean on the BROKEN output, both
; instances. Only `free_pairing_check.py` (e2e stage 2b) and this fixture see it.
;
; WHY IT NEEDS A `cqrt_alloc_` ROOT AND HAND-WRITTEN IR. A rail whose first write
; follows a read of it must have a def that is not its own first gate — i.e. an
; alloc root, not a `cq_template_*` producer (whose `railOf` is the producer itself,
; which dominates every use). Every C-reachable alloc root is immune because
; `RotationLowering` emits `cqrt_alloc_<W>` and its birth `cqrt_ry_<W>` back to
; back, so the birth rotation precedes every later borrow. Hand-written IR reaches
; it (the pass carves every `cqrt_*` callee out of `declineTaintEscapes`) — MEASURED
; over 19 targeted C probes in the Rule-13 round without reaching it from C. That is
; a statement about today's emitters, not about the spine, so the invariant is fixed
; rather than the input declined.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)

define void @borrowed(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %q3 = call i32 @cq_theta_si32(i32 %u2, double 1.250000e-01)
  %z  = call i32 @cqrt_alloc_i32(i32 %q2)     ; borrowed as the GUARDED store's flag
  %v  = call i32 @cqrt_alloc_i32(i32 %q3)     ; borrowed as the PLAIN store's value
  call void @cqrt_qram_store_i32_controlled(i32 %z, i32 %q, i32 3, i32 4)
  call void @cqrt_qram_store_i32(i32 %q, i32 3, i32 %v)
  ; Each borrowed rail's own first gate lands AFTER the gate that reads it:
  call void @cqrt_ry_i32(i32 %z, double 7.500000e-01)
  call void @cqrt_ry_i32(i32 %v, double 6.250000e-01)
  call void @cqrt_ry_i32(i32 %q, double 1.000000e-01)
  ret void
}

; The reversal runs in reverse program order. Each borrowed rail's free must come
; after the adjoint of the store that reads it — i.e. both `_unc`s first, then the
; two frees. FileCheck matches in sequence, so a free that moved back above its
; reader's `_unc` (the pre-fix output, for either rail) cannot satisfy these:
; CHECK:     call void @cqrt_ry_i32(i32 %[[V:[a-zA-Z0-9_.]+]], double -6.250000e-01)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Z:[a-zA-Z0-9_.]+]], double -7.500000e-01)
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3, i32 %[[V]])
; CHECK:     call void @cqrt_free(i32 %[[V]])
; CHECK:     call void @cqrt_qram_store_i32_controlled_unc(i32 %[[Z]], i32 %[[H]], i32 3, i32 4)
; CHECK:     call void @cqrt_free(i32 %[[Z]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
; CHECK-NOT: cqrt_measure
