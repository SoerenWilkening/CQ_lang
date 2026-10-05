; control_inplace_ry_reject_lifted_phi_ret.ll — DECLINE. R6, the stale-rail-record fence, reached through a
; LIFTABLE ONE-REGISTER CLASSICAL MERGE φ. One of seven consumer kinds pinned
; after the round-1 Rule-13 review of bd test_C_libtooling-drbq Inc 1 (lens L2
; §1) MEASURED all seven ACCEPTING — `opt` exit 0, `opt -verify` clean,
; `free_pairing_check.py` STRICT clean, and green against all 37 committed
; fixtures of this family.
;
; THE LAUNDER, which is the same in all seven:
;
;     int m; if (c) { m = r; } else { m = r; }              /* CLASSICAL diamond */
;     if (q == 5) { cq_theta(&r, .9); }                    /* in-place Ry on r  */
;     ... <consumer>(m) ...                                    /* reads the PRE-Ry record */
;
; `m` and `r` are two SSA names for ONE physical rail (pre-3qlq one edge carried
; an in-place `cq_phi` Rz). Inc 1's `railWireClosure` crossed a `PHINode` BACKWARD
; but not FORWARD, so the classical join φ was a plain USER of a member: it passes
; `provablyBefore` HONESTLY (it dominates the region's branch and the branch
; cannot reach it), R6 stopped there, and ITS users were never enumerated.
; `liftOneRegisterMergePhi` then RAUW'd the φ to the base AFTER the region was
; emitted, so the consumer read the POST-Ry register where the source names the
; record BEFORE it — the wrong-VALUE class of bd 0njv, which R6 exists to keep
; unreachable through this accept.
;
; The compensating re-sweep `declineLiftedStaleRecordOps` does NOT cover this:
; its scope (`inLowerOpsScope`) is binary/unary/cast/data-compare/curated-
; intrinsic, and none of the seven consumers below is in it. The straight-line
; twin (drop the classical `if`) declined all along, which is what makes the
; classical diamond the launder rather than the defect.
;
; CONSUMER PINNED HERE: `ret m` — the laundered record ESCAPES to the caller. MEASURED
; returning the relabelled handle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %cc = icmp eq i32 %c, 0
  br i1 %cc, label %join, label %alias
alias:
  br label %join
join:
  %m = phi i32 [ %r, %alias ], [ %r, %entry ]
  %t = icmp eq i32 %q, 5
  br i1 %t, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %join ]
  %b = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
