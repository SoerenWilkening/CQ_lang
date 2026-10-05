; control_inplace_ry_alias_after_region.ll — ACCEPT spec: an alias hop minted
; AFTER the region, off the MERGE φ (control-in-place-PRD §4 R6; bd
; test_C_libtooling-drbq Inc 1, finding J's second positive control).
; `clang -O1` output (attribute groups and metadata trimmed) for
;
;     int example(int u0, int u1) {
;       int q = u0; cq_theta(&q, 0.5);
;       int r = u1; cq_theta(&r, 0.3);
;       if (q > 5) cq_theta(&r, 0.9);
;       cq_theta(&r, 0.1);              /* the hop, off the POST-region name */
;       return cq_measure(r);
;     }
;
; The mirror image of control_inplace_ry_reject_stale_measure.ll, and the reason
; R6 is a POSITION rule and not an alias BAN: this hop (`%10 = cq_theta(%9,
; .1)`) hangs off the merge φ, which the emitter RAUWs to the base, so it acts on
; the register AFTER the controlled Ry relabelled it — exactly what the source
; means. The merge φ is the closure's ONE forward exclusion (`railWireClosure`'s
; `Exclude`), so its descendants are never asked the staleness question at all.
;
; History: pre-3qlq the hop was the register form `int mark = cq_phi(r, .1)`
; (in-place Rz) off the merge. The 3qlq migration deleted it as an uncontrolled
; phase, which left a plain read of the merge, the same module as
; control_inplace_ry_alias_chain_consumed.ll; bd jttf (2026-10-05) re-spelled
; the hop as the in-place Ry above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the hop is emitted AFTER the gate, on the register the gate relabelled
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[M]]
;
; NEG-NOT: cqrt_cswap
; NEG-NOT: phi i32
; NEG-NOT: cq_theta_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @example(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %5 = icmp sgt i32 %3, 5
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 9.000000e-01) #2
  br label %8

8:                                                ; preds = %6, %2
  %9 = phi i32 [ %7, %6 ], [ %4, %2 ]
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 1.000000e-01) #2
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %11
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
