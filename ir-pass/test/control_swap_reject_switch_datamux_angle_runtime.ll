; control_swap_reject_switch_datamux_angle_runtime.ll — DECLINE. The
; `control_swap_reject_switch_datamux_angle.ll` shape (a 4.5 all-`ConstantInt`
; DATA-MUX `switch` whose merge result is compared and used as a rotation ANGLE
; selector) with RUN-TIME angle arms instead of constants.
;
;     %rm  = phi [3, entry], [7, a0], [9, a1]     ; the 4.5 data mux
;     %c   = icmp ne i32 %rm, 0                   ; tainted after the dugh
;     %ang = select i1 %c, double %a, double %b   ;   second propagation
;     cq_phi(%qx, %ang)
;
; THE SIBLING FILE, WITH CONSTANT ARMS 0.9/0.3, ACCEPTS. This one declines, and
; the ONLY difference between the two modules is how the two angles are spelled.
; That is the whole content of the Increment-2b clearance ruling (bd
; `test_C_libtooling-drbq`, finding F-11 / blocker B1, graded
; CONFIRMED-MISCOMPILE; orchestrator decision: ship option (2), the accept narrows
; to CONSTANT arms): for RUN-TIME arms the compiler SYNTHESIZES an `fsub` the
; source never wrote, the realized true-arm angle is `B + fl(A−B)`, and
;   (i)  the error `|delta| <= 1/2 ulp(A−B)` is UNBOUNDED in absolute radians
;        (measured 0.858 rad from plain C: `Ry(pi)` realized as `Ry(4.0)`), and
;   (ii) `fl(A−B)` can be `inf`/`NaN` from two ORDINARY FINITE arms (measured:
;        `cqrt_ry_i32_controlled(f, h, inf)`).
; Neither is fenceable at compile time; the pre-2b binary declined the shape
; loudly; and the manual by-difference twin with run-time arms declines
; `control flow under quantum control` on BOTH binaries, so the residual was
; reachable ONLY through 2b. The full argument, the five reproducers and the
; owner's one-line widening option (1) are in
; `control_angle_select_reject_runtime_arms.ll`'s header.
;
; WHAT THIS FILE ADDS OVER THAT ONE, and it is why it is a separate cell rather
; than a third parameter spelling: the arm-value fence must hold on the **yn71
; ONWARD-CONTROL FIXPOINT** path too. This region is detected and emitted inside a
; LOCAL `plan2` that is built, emitted and DISCARDED, on a condition that is only
; tainted by the dugh SECOND propagation (`repropagateControlMerges` re-seeds from
; the 4.5 `%out` rail). S1 runs in `classifyAngleSelect` for that path exactly as
; for the first-plan one — this fixture is the measurement of that, not an
; assumption about it.
;
; THE 4.5 DATA MUX ITSELF STILL LOWERS: declining the angle select is a decline of
; the whole module (`DS_Error` exits non-zero and nothing is written), so this
; file asserts the DIAGNOSTIC only. Its accepting sibling is where the emitted
; stream is pinned.
;
; NO NEW DIAGNOSTIC STRING: S1 returns `NotApplicable` and `SelectClassify` gate
; 3's pre-existing `rotation angle` decline fires — which is byte-identical to the
; disposition this exact module had on the PRE-2b binary and for the whole of 4.5.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (angle select -> void call on the select (PRD P2))

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %u1, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %c = icmp ne i32 %rm, 0
  %ang = select i1 %c, double %a, double %b
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %qx)
  ret i32 %m
}

; CHECK-NOT: fsub double
; CHECK-NOT: cqrt_rz_i32_controlled
