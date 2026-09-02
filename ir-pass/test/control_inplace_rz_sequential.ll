; control_inplace_rz_sequential.ll — the §6a Rz peephole on TWO SEQUENTIAL flat
; regions, the bd `hcrg` shape (bd test_C_libtooling-drbq Inc 2a).
;
; `if (q>5) rz(r,a); if (q>9) rz(r,b);` — after `-O1` the second region's tainted
; branch lives in the FIRST region's merge block, which is the shape that declined
; as "nested control flow" for four months until `hcrg` replaced the structural
; guard with an emission-ORDER one. Nothing about that changes here; what this
; fixture pins is that the ORDER survives the peephole.
;
; WHY ORDER IS AT RISK AND NOT MERELY DECORATIVE. `lowerControlRegions`
; Kahn-sorts the regions by a precedence graph, so region 2 may be EMITTED first;
; each emitter inserts positionally into its OWN pred block, which is what keeps
; the emitted stream in SOURCE order. Inc 2a adds a second positional actor — the
; HOIST (`moveBefore(BI)`) — and a deferred one, `lowerRotations`, which mints
; each controlled gate at the hoisted position. So "region 1's whole stream, then
; region 2's whole stream, each with its own flag minted / stripped / freed" is a
; property this increment could have broken and did not.
;
; Two flags, two strips, two frees, and NO interleaving.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; The ROUTE'S ABSENCE, on its own prefix anchored at the function header. A
; trailing CHECK-NOT scans only past the LAST positive of its own prefix, and every
; route line lands BEFORE that, so it could never fire (bd memory
; filecheck-check-not-window-trap). The window reaches the declares too, hence the
; `call void @` anchors.
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact free count: TWO (one flag per region), no third.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %r1 = call i32 @cq_phi_si32(i32 %r, double %a)
  br label %m1
m1:
  %rm1 = phi i32 [ %r1, %arm1 ], [ %r, %entry ]
  %c2 = icmp sgt i32 %q, 9
  br i1 %c2, label %arm2, label %m2
arm2:
  %r2 = call i32 @cq_phi_si32(i32 %rm1, double %b)
  br label %m2
m2:
  %rm2 = phi i32 [ %r2, %arm2 ], [ %rm1, %m1 ]
  %ma = call i32 @cq_measure_si32(i32 %rm2)
  %mb = call i32 @cq_measure_si32(i32 %q)
  %o = add i32 %ma, %mb
  ret i32 %o
}

; region 1: mint, gate, strip, free — complete before region 2 starts
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[R:[a-zA-Z0-9_.]+]], double %a)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; region 2: its own flag, on the SAME register, in source order
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 9)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[R]], double %b)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  call void @cqrt_free

; NOROUTE: define i32 @example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: phi i32

; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
