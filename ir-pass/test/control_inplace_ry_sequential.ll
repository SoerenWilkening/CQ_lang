; control_inplace_ry_sequential.ll — ACCEPT spec: TWO control-in-place rotation
; regions in sequence on ONE register (bd test_C_libtooling-drbq Inc 1).
;
;     if (q > 5) r = cq_theta(r, .9);
;     if (q > 7) r = cq_theta(r, .4);
;
; After `clang -O1` the first region's MERGE BLOCK hosts the second region's
; tainted branch, which is the bd `hcrg` sequential-chain shape: block lifetime is
; resolved by `lowerControlRegions`' precedence graph (emit the LATER region
; first, since its `Pred` is the earlier region's doomed merge), not by declining.
; This fixture proves the new arm class rides that machinery unchanged — its
; regions carry no `Arm`/`Merge` aliasing the graph does not already understand.
;
; SEMANTICALLY it is also the composition check: region 2's base is region 1's
; MERGE φ, which region 1's emitter RAUW'd to the shared register. So the second
; controlled Ry reads the register the first one relabelled — exactly what the
; source means (`r` after the first `if`) — and each region mints, strips and
; frees ITS OWN flag, so neither flag is live across the other's gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %arm2, label %merge2
arm2:
  %rt2 = call i32 @cq_theta_si32(i32 %rm, double 4.000000e-01)
  br label %merge2
merge2:
  %rm2 = phi i32 [ %rt2, %arm2 ], [ %rm, %merge ]
  %m   = call i32 @cq_measure_si32(i32 %rm2)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; region 1 — its own flag, minted / used / stripped / freed before region 2 starts
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; region 2 — a SECOND flag, on the SAME register, in source order
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R]], double 4.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  phi i32

; two flags, two frees, and still no work rail (two allocs = the two registers)
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
