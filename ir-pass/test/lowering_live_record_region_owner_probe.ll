; lowering_live_record_region_owner_probe.ll — OWNERSHIP PROBE (M-A Increment 1,
; bd test_C_libtooling-6uqc). A chained theta AFTER a tainted phase region keeps
; declining with `ArmClassify`'s OWN message, not the new live-record one.
;
; This is bd test_C_libtooling-lom0's shape — the Grover re-prep wall. The
; live-record guard runs at the LATE slot (post-`uncompute`, run-line ~470),
; while `detectControlRegions` declines this at run-line 321 and `opt` exits at
; that first `DS_Error`. So the new guard cannot re-own a message an earlier
; stage already owns, and census 0.4's 9 at-risk negative fixtures are safe by
; ORDER rather than by a carve-out.
;
; IT ALSO RECORDS WHY THE `ShareCondFlag` PROBE HAS NO ACCEPT FIXTURE: a shared
; control/data flag rail that is stripped by Phase 4 and then read as data past a
; chained theta needs exactly this program shape, and this program shape is
; unreachable today for an unrelated reason. When bd lom0's position-aware accept
; lands (Inc 4), this fixture becomes the place to re-measure who owns it — the
; region's compare flag is minted, stripped and freed BEFORE the gate, so it is
; discharged by clause 2, but the region's derived-provenance chain (bd 6uqc's
; interlock) is not, and that is the case Inc 4 must not accept blind.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
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

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
