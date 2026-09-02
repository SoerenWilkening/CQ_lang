; control_swap_inloop_seq.ll — ACCEPT (bd test_C_libtooling-8h7d.5, Phase 7.3
; Increment 3). A SEQUENTIAL PAIR of tainted-condition phase regions inside one
; classically-bounded loop body — the shape the customer program is written in
; (an oracle and a reflection, per trip).
;
; THIS FILE WAS `control_swap_reject_seq_in_loop.ll` UNTIL 2026-08-29 and its
; original job survives the flip: it is still the ONLY fixture that drives the
; sequential pair through the DIAMOND/IFELSE dispatch arm (bd hcrg moved it there
; from the NESTED arm), and it is still the only one that exercises the bd hcrg
; EMISSION ORDER inside a loop — region 2 must be emitted BEFORE region 1,
; because region 1's flatten erases the block (`%m1`) that region 2 names as its
; `Pred`. Both facts are now checked positively rather than through a decline.
;
; The block-lifetime hazard and the d8jl loop hazard were always DIFFERENT
; problems wearing one message, and this fixture is where that shows: ordering
; resolves the first (`lowerControlRegions`' precedence graph), and
; `flattenRegion`'s `replaceSuccessorsPhiUsesWith` repairs the second. Emission
; ORDER is invisible in the output because each emitter inserts positionally into
; its own pred block, so the gate stream is still source order — region 1's flag
; first.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %m2 ]
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %m1
m1:
  %p1 = phi i32 [ %g1, %arm1 ], [ %q, %head ]
  %c2 = icmp sgt i32 %p1, 3
  br i1 %c2, label %arm2, label %m2
arm2:
  %g2 = call i32 @cq_phi_si32(i32 %p1, double %b)
  br label %m2
m2:
  %p2 = phi i32 [ %g2, %arm2 ], [ %p1, %m1 ]
  %mm = call i32 @cq_measure_si32(i32 %p2)
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, 4
  br i1 %done, label %head, label %exit
exit:
  ret i32 %mm
}

; ONE loop block, TWO rolled streams, in SOURCE order (a=first, b=second):
; CHECK:     head:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[H]], double %a)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[H]], double %b)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK:     br i1 %{{.*}}, label %head, label %exit
;
; Both merges (`%m1`, `%m2`) were spliced away and nothing dangles:
; CHECK-NOT: Broken module
; CHECK-NOT: control flow inside a loop body
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
