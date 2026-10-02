; lowering_volatile_scalar_deadstore.ll — ACCEPT (bd k710): DEAD volatile SCALAR
; STORE elimination, the WRITE-ONLY sibling of the etiq const fold. This is
; openlibm's underflow idiom verbatim (ld80/s_nexttowardf.c:63):
;
;     if(hy<0x00800000) { volatile float u = x*x; }   /* underflow */
;
; `u` is NEVER READ. With zero loads neither the etiq const fold (needs loads to
; fold) nor zco4's promotion (`Loads.empty()` forfeits, and with nothing to
; promote PromoteMemToReg would only delete the store) can claim it, so the
; volatile store survives to `declineTaintEscapes` and the cell dies on
; kMsgStore — see the sibling decline fixtures.
;
; GROUND: the fenv ruling (owner 2026-08-10, CLAUDE.md "Scope of the semantic
; model"). CQ models no FP exception flags, and a volatile access to a
; NON-ESCAPING function-local is not observable, so the store is dead.
;
; ⚠⚠ bd vsfp ROUND 2 (bd test_C_libtooling-qjoc; bd vsfp Rule-13 r1B F-VB-7) — THE
; ASYMMETRY THIS FIXTURE USED TO PIN IS GONE, AND THE HALF IT PINNED WAS NOT "HARMLESS".
; It pinned the no-control-flow half: the dead product `x*x` was lowered, uncomputed
; and freed, "a useless but harmless gate pair". That was true of THIS module and
; false of the class: a dead 4.4 select left behind the same way got its `%out`
; which-path rail minted and never discharged (silent dephasing, bd qjoc), and a dead
; template product whose source later took a non-diagonal gate was left DIRTY
; (warned). The stage now deletes the erased store's DEAD cone itself, with the
; pass's ONE liveness predicate (`DeadValueLiveness.h`), so the circuit is the same
; inside and outside a PredMux region: the computation is gone — what the fenv
; ruling licenses ("the computation then usually disappears too"). CLAUDE.md's
; owner-ruled fenv section still says "Both are sound"; that sentence is FLAGGED to
; the owner in the bd vsfp record (TRACK_VSFP §6), not edited.
;
; What remains on this module: `%p` is a user `cq_theta` (a liveness ROOT, never
; deleted) with no other reader, so its rail is allocated, rotated and reversed by
; the ordinary whole-DAG spine — exactly the hand-written program without the
; volatile line. It is not freed: Ry-dagger restores its runtime seed |u1>, not |0>
; (bd 5c5b, libcqops vmz9).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

; NB the dead product is rooted at its OWN theta (%p), not at the measured rail.
; Rooting it at %q instead makes the whole-DAG spine decline `cq uncompute: dead
; chain would free a measured register` — a correct, pre-existing Rule-6 guard
; that has nothing to do with this stage, and which is pinned separately by
; lowering_reject_volatile_scalar_deadstore_measured.ll. Keeping the two apart is
; what lets this fixture fail for THIS stage's reasons only.
define float @probe(float %u0, float %u1) {
entry:
  %u = alloca float, align 4
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %p = call float @cq_theta_f32(float %u1, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %u)
  %uu = fmul float %p, %p
  store volatile float %uu, ptr %u, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %u)
  %m = call float @cq_measure_f32(float %q)
  ret float %m
}

; The WHOLE body is pinned instruction-for-instruction. That is deliberate: a
; CHECK-NOT on `store volatile` alone would also be satisfied by the store simply
; moving, and `CHECK-NOT: llvm.lifetime` matches the surviving DECLARATION rather
; than a call. An exact CHECK-NEXT chain from the first alloc to the `ret` leaves
; nowhere for an unerased store, marker or alloca to hide.
;
; CHECK-LABEL: define float @probe(float %u0, float %u1)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float %u0)
; CHECK-NEXT:  call void @cqrt_ry_f32(i32 %[[M]], double 5.000000e-01)
; CHECK-NEXT:  %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float %u1)
; CHECK-NEXT:  call void @cqrt_ry_f32(i32 %[[R]], double 5.000000e-01)
;
; No product, no template, no adjoint pair — the dead `fmul` went with the store.
; The now-unread `%p` rail is reversed by the spine and KEPT (Rule 6: a free needs
; |0>, and Ry-dagger restores the runtime seed |u1>; bd 5c5b):
; CHECK-NEXT:  call void @cqrt_ry_f32(i32 %[[R]], double -5.000000e-01)
;
; the measured rail is a DIFFERENT one and is never freed — the measurement owns
; it (Rule 6):
; CHECK-NEXT:  %{{[a-zA-Z0-9_.]+}} = call float @cqrt_measure_f32(i32 %[[M]])
; CHECK-NEXT:  ret float
