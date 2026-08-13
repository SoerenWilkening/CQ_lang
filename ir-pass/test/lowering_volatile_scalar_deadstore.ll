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
; *** WHAT THIS FIXTURE PINS IS THE NO-CONTROL-FLOW HALF OF AN ASYMMETRY, AND IT
; MUST NOT BE READ AS "THE COMPUTATION ALWAYS SURVIVES". *** Here there is no
; enclosing tainted branch, so nothing invokes PredMuxFlatten.cpp:2618's
; `RecursivelyDeleteTriviallyDeadInstructions`; the now-dead product therefore
; reaches `lowerOps`, is emitted as a template call, and is then uncomputed and
; freed by the whole-DAG spine — a useless but harmless gate pair. INSIDE a
; PredMux region the same product is deleted outright, and the shipped
; `slice_libm_real_nexttowardf` golden has ZERO `fmul_f32` for exactly that
; reason. Both outcomes are sound under the fenv ruling; they are not the same
; circuit.
;
; That distinction is recorded here because a tidier claim — "the stage removes
; the store, so the computation survives" — was put to the owner when the ruling
; was requested, and was an artifact of a fixture shaped like THIS one. The
; ruling was re-affirmed on the measured facts. Do not restore the tidier claim.
;
; So the CHECKs below assert what actually happens on this shape: the product is
; lowered, then its adjoint runs, THEN the rail is freed (Rule 6 — freed only at
; |0>). They are a Rule-6 pairing pin, not a "computation is protected" pin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
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
; On THIS shape (no enclosing tainted branch) `x*x` still lowers, on the rail, as
; a Q+Q template call — bare symbol; `_hl`/`_lh` are the mixed shapes. See the
; asymmetry note in the header: this is not a guarantee the pipeline makes in
; general, it is what happens when the PredMux DCE path is not reached.
; CHECK-NEXT:  %[[P:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f32(i32 %[[R]], i32 %[[R]])
;
; and because the product is now dead, the whole-DAG spine does its ordinary job
; on it — adjoint FIRST, then free, so the rail is provably |0> at the free and
; Rule 6 holds. The source rail's own Ry is reversed and it is freed after:
; CHECK-NEXT:  call void @cq_template_fmul_f32_unc(i32 %[[P]], i32 %[[R]], i32 %[[R]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[P]])
; CHECK-NEXT:  call void @cqrt_ry_f32(i32 %[[R]], double -5.000000e-01)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[R]])
;
; the measured rail is a DIFFERENT one and is never freed — the measurement owns
; it (Rule 6):
; CHECK-NEXT:  %{{[a-zA-Z0-9_.]+}} = call float @cqrt_measure_f32(i32 %[[M]])
; CHECK-NEXT:  ret float
