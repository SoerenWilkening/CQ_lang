; spec_accept_qrom_read_arm_provable_index.ll — bd 20xt.7 (the Provable-pow2
; clone-read mask): a const-global tainted-index QROM read in a tainted diamond arm
; of a Phase-6 spec-clone, coherently escaping to the clone ret — as in
; spec_accept_qrom_read_arm_coherent_escape.ll — BUT the region-internal phi-index
; ranges over IN-BOUNDS constants only (`{0,1}`, no OOB sentinel), so the E4 claim
; verdict is `Provable`, not `NeedsMask`.
;
; Pre-20xt.7 this DECLINED at the emitter (`kMsgQramCloneUnbounded`, "index not
; provably in-bounds"): a Provable read recorded NO mask, so after `lowerCloneSelect`
; lowered the index to an opaque `cqrt_alloc_i64` handle, `lowerQramReads`'
; `qromIndexKnownInBounds` re-proof could no longer see the pre-flatten Provable
; proof — a SAFE-but-confusing claim/emit divergence (the E4 claim accepted, the
; emitter rejected). 20xt.7 records a Provable clone read on a pow2 table in
; `R.MaskLoads` too, so the flatten emits the IDENTITY mask `and idx, N-1` (inert on
; a provable-in-bounds index — Provable ⟹ known-bits max < N = 2^k ⟹ `and idx, N-1`
; == idx at runtime), carrying the claim's bounds proof to the emitter. Clone-only
; (ClaimAll): a top-level Provable read stays UNMASKED (the Inc-1 faithful-read
; contract). A non-pow2 Provable clone read stays declined (safe residual).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

@tbl = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @lookupP(double %x) {
entry:
  %c1 = fcmp ogt double %x, 1.000000e+00
  br i1 %c1, label %inner, label %base
inner:
  %c2 = fcmp olt double %x, 2.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i64 [ 0, %ia ], [ 1, %ib ]           ; {0,1} in-bounds for [4] -> Provable
  %g = getelementptr inbounds [4 x double], ptr @tbl, i64 0, i64 %id
  %v = load double, ptr %g, align 8
  %s = fadd double %x, %v
  br label %exit
base:
  br label %exit
exit:
  %r = phi double [ %s, %join ], [ %x, %base ]
  ret double %r                                  ; coherent escape — no measure
}

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookupP(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; The Provable read gets the IDENTITY mask (`and .., 3`) so it lowers exactly like a
; NeedsMask read; the clone is otherwise identical to the coherent-escape accept.
; CHECK-LABEL: define internal {{.*}}i32 @__cq_q_lookupP_1(i32 %x)
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:     %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 3)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %[[IDX]])
; the diamond is FLATTENED and the read LOWERED — no raw load / control survives:
; CHECK-NOT: load double
; CHECK-NOT: br i1
; CHECK-NOT: = phi
; CHECK-NOT: = select i1
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_qram_load_f64_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[IDX]])
; the reverse is `_unc` (never `_inv`); the entangled array handle + result rail are
; NEVER freed (Rule 6/8):
; CHECK-NOT: cqrt_qram_load_f64_inv
; CHECK-NOT: cqrt_free(i32 %[[ARR]])
; CHECK-NOT: cqrt_free(i32 %[[OUT]])
; CHECK:     ret i32 %[[OUT]]
