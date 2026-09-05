; control_inplace_ry_stateprep_intrinsic_bswap_accept.ll — ACCEPT, and it is the
; ONE-TOKEN CONTROL that makes F2's EXACT-FOLD half a discriminator instead of a
; decoration.
;
; It is `..._reject_stateprep_intrinsic_bswap.ll` with the seed changed from 5 to
; 7 and nothing else. `%q` is pinned to `{83886080}` on the arm edge, so
; `llvm.bswap.i32(%q)` is EXACTLY 5 — which is not the seed, so the region is
; unambiguous and accepts.
;
; ⚠ WHY IT HAD TO BE WRITTEN (round-3 Rule-13 fix, mutation M5). Disabling F2's
; exact `ConstantFold*` half reddened ZERO fixtures: with the fold gone,
; `llvm.bswap` is not one of the intrinsics `ConstantRange::isIntrinsicSupported`
; models, its operand IS pinned, and F2's CONSERVATIVE half declines it anyway —
; so every intrinsic DECLINE fixture in the family passes for the weaker reason
; and none of them can tell the two halves apart. This file can: under M5 it
; flips to a DECLINE. Precision, not safety, is what the exact fold buys, and
; this is where that is pinned.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare i32 @llvm.bswap.i32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 83886080
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_ui32(i32 7, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 7, %entry ]
  %t = call i32 @llvm.bswap.i32(i32 %q)
  %mr = call i32 @cq_measure_ui32(i32 %rm)
  %mt = call i32 @cq_measure_ui32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}

; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 {{.*}}, i32 %[[R]], double 9.000000e-01)

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
