; lowering_live_record_region_owner_probe.ll — RE-DISPOSITIONED AT INCREMENT 4:
; this module now LOWERS, and the ownership question it was written to record
; has an answer.
;
; WHAT IT WAS. An M-A Increment-1 ownership probe (bd test_C_libtooling-6uqc): a
; chained theta AFTER a tainted phase region kept declining with `ArmClassify`'s
; OWN message, not the new live-record one, because the live-record guard runs
; at the LATE slot (post-`uncompute`) while `detectControlRegions` declined this
; at detection and `opt` exits at the first `DS_Error`. The probe's conclusion —
; census 0.4's at-risk negatives are safe by ORDER rather than by a carve-out —
; is unchanged and still holds for every shape that still declines at detection
; (control_swap_reject_post_region_theta_{valuearm,sharecond,nested,and_between,
; loop}.ll are the current partition of those).
;
; WHAT IT IS NOW. This IS bd test_C_libtooling-lom0's shape — the Grover re-prep
; wall — and Increment 4 lifted it. The header used to say "when bd lom0's
; position-aware accept lands (Inc 4), this fixture becomes the place to
; re-measure who owns it". Re-measured:
;     HEAD b4e329b   declines, "condition predates a non-diagonal gate"
;     Increment 4    `opt` exit 0, the stream below
; and NOBODY owns a decline, correctly. The region's condition is DIRECT (an
; `icmp` on the register itself), so the compare flag is the region's sole record
; of the wire and the `_unc` strip + `cqrt_free` discharge it — clause 2 of the
; live-record guard — BEFORE the chained `cqrt_ry_i32` fires. There is no derived
; provenance chain (contrast control_swap_reject_post_region_theta_derived_cond.ll,
; which has one and therefore still declines, at the guard) and no dead ancestor
; rail (contrast lowering_reject_live_record_routed_base_anc.ll). Two allocations
; exist in the whole program and one of them is freed.
;
; KEEPING THE FILE UNDER ITS OLD NAME IS DELIBERATE. Its value was never the
; exit code; it was the record of WHICH STAGE speaks for this program, and that
; is exactly what moved. If a future increment makes it decline again, the first
; question is which of the two stages started speaking — and this header is where
; the previous answer is written down.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:
  %qz = call i32 @cq_phi_si32(i32 %q, double 3.140000e+00)
  br label %merge

merge:
  %p  = phi i32 [ %qz, %arm ], [ %q, %entry ]
  %q2 = call i32 @cq_theta_si32(i32 %p, double 5.000000e-01)
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R]], double 3.140000e+00)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK:     call void @cqrt_free(i32 %[[R]])
; The strip and the flag free BOTH precede the chained Ry — the discharge this
; accept rests on, in the emitted order rather than in prose.
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: phi
; CHECK-NOT: br i1
;
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
