; control_classical_call_arm_accept_onward_phase.ll — ACCEPT (dugh, Phase 4×6): a
; 6.5 classical-call arm whose UNTAINTED merge (`int y = 5; if (q>3) y = f(a)`)
; feeds an ONWARD, UNCONTROLLED, IN-PLACE quantum gate that terminates at a
; measurement. `clang -O1` output (target attributes and metadata trimmed; `@f`'s
; purity/totality attributes kept) for
;
;     __attribute__((noinline)) int f(int a) { return a + 100; }
;     int example(int u0, int a) {
;       int q = u0; cq_theta(&q, 0.5);
;       int y = 5;
;       if (q > 3) y = f(a);
;       cq_theta(&y, 0.25);       /* the onward gate, in place on the merge */
;       return cq_measure(y);
;     }
;
; PRE-dugh this DECLINED at the classifier's merge-out gate (the merge is
; data-untainted, so the onward gate read the i32 %out handle as a classical
; value). dugh RE-SEEDS a second propagation from the emitted `%out`
; (`repropagateControlMerges`): the onward `%9 = cq_theta(%8, 0.25)` is
; re-tainted as a CHAINED rotation and lowers IN PLACE to `cqrt_ry_i32(%out,
; 0.25)` (the answer stays on %out, zero controlled gates, no fresh rail); `%m`
; measures %out.
;
; Trace reasoning: the copy merge leaves `%out` = f(a) on the q>3 branch and 5
; elsewhere (two X-bracketed controlled copies into a |0> rail; the flag is
; stripped back to |0> and freed). The onward Ry then rotates that one rail,
; exactly the source's `cq_theta(&y, .25)` on `y`, and the measurement reads it.
; `%out` (a ControlOwnedRail) and the two copy-operand rails are left allocated
; (they hold f(a) and 5, not |0>).
;
; This module also prints `warning: ... non-diagonal gate over a live derived
; record` (the M-A guard), and the warning is RIGHT; it is pinned below (ACC).
; The gate is the onward Ry on `%out`, but no record is `%out`'s own rail
; (measured with a record-dump build, bd aako 2026-10-05). The guard counts
; three: `q`'s rail %[[H]] and the two copy sources %[[S1]] / %[[S2]].
; %[[H]] is the real one. At the gate the state is sum_h c_h |h>_H |g(h)>_OUT with
; g(h) = (h > 3) ? f(a) : 5, and nothing reads `q` again, so %out's reduced state
; is diagonal and the Ry acts on a mixture; `q` cannot be discharged first because
; %out depends on it. That is the user's circuit (owner ruling lyyf): warn and
; lower. The copy sources hold the classical constants f(a) and 5 and are only
; ever CONTROLS of the Toffoli copy, so they stay product states. Counting them
; is an over-count, but it cannot change this verdict while %[[H]] is dead.
; Measuring `q` after the gate exempts %[[H]] and leaves the copy sources warning
; alone; that over-warning is reported with aako, not pinned here.
;
; History: written for the pre-3qlq register form `y = cq_phi(y, 0.25)`, an
; onward PHASE lowered in place as `cqrt_rz_i32(%out, 0.25)` (the tensored Rz
; 3qlq retired). The 3qlq migration deleted that uncontrolled phase and left a
; plain merge-then-measure; bd jttf (2026-10-05) re-spelled the onward gate as
; the in-place Ry above. The register-free onward PHASE is a branch phase on the
; merge, which is control_classical_call_arm_accept_onward_ctl_phase.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACC < %t.err
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it needs a TOTALITY proof as well as a purity one, and a
; visible pure body with `willreturn memory(none)` supplies it
; (`isSpeculatableTotalCallee`). The opaque spelling DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (a visible partial body is
; hoisted only as its guarded twin: control_classical_call_arm_twin_accept_partial_callee.ll).
define range(i32 -2147483548, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

define i32 @example(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @f(i32 noundef %1)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ 5, %2 ]
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.500000e-01) #3
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

; the hoisted classical call, then the controlled-XOR copy merge into %out:
; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[FA:[0-9]+]] = tail call i32 @f(i32 noundef %1)
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F1]], i32 %[[OUT]], i32 %[[FA]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F1]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; the ONWARD gate lowers IN PLACE on %out (no fresh rail, uncontrolled):
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[OUT]], double 2.500000e-01)
; the measure reads %out:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: ret i32 %[[M]]

; whole-module: no controlled rotation, no surviving front-end intrinsic, no route,
; and %out is never freed (it is measured):
; NEG-NOT: cqrt_ry{{.*}}_controlled
; NEG-NOT: cqrt_rz
; NEG-NOT: cq_theta_si32
; NEG-NOT: cqrt_cswap
; NEG-NOT: call void @cqrt_free(i32 %out)
; the region ACCEPTS (no decline diagnostic) and M-A warns once, on the onward
; gate (`q`'s rail %[[H]] stands as a dead record of %out; see the header):
; ACC-NOT: under quantum control
; ACC-NOT: error
; ACC:     warning: {{.*}}in function example i32 (i32, i32): cq rotation lowering: non-diagonal gate over a live derived record
; ACC-NOT: warning
; ACC-NOT: error
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05
