; control_inplace_ry_alias_pre_region_branch.ll — ACCEPT spec: an in-place alias
; hop on a CLASSICALLY-BRANCHED path ahead of the region (bd
; test_C_libtooling-drbq Inc 1, finding J: the one shape that fix ACCEPTS that
; Inc 1 declined). `clang -O1` output (attribute groups and metadata trimmed) for
;
;     int example(int u0, int u1, int opaque) {
;       int q = u0; cq_theta(&q, 0.5);
;       int r = u1; cq_theta(&r, 0.3);
;       if (opaque) cq_theta(&r, 0.1);   /* the hop: in place on r, classically */
;       if (q > 5)  cq_theta(&r, 0.9);   /* the controlled Ry                   */
;       return cq_measure(r);
;     }
;
; R6 asks a POSITION question about a read: can it observe the register AFTER the
; controlled Ry relabels it? Inc 1 answered with `provablyBefore`, which is that
; question (`BI` cannot reach `U`) AND a second one it never needed (`U` dominates
; `BI` — "did U definitely execute"). With the fence ranging over the rail's ALIAS
; CLOSURE the extra conjunct became WRONG-STRONG: `control_inplace_ry_sequential`'s
; region 2 has region 1's ARM THETA as a member's user, and an arm block dominates
; nothing. So an alias HOP now owes only `cannotFollowGate`; every other user keeps
; `provablyBefore` verbatim (two sets, two questions — bd 8h7d.5 round 3).
;
; Here the hop `%8 = cq_theta(%5, .1)` sits in the side block `7`, which does not
; dominate the region's branch, so `provablyBefore` would refuse it; it cannot
; follow the gate, so `cannotFollowGate` admits it. The classical join
; `%10 = phi [%8, %7], [%5, %3]` is the 5j5 one-register merge phi (lifted to
; `%5`), and it is the region's base.
;
; The emitted order is what makes it sound, and the CHECKs below pin it: the hop
; stays in its own conditionally-executed block, the controlled Ry is emitted in
; the region's pred, and the source's order (hop THEN gate) survives on every
; path. Per shot: Ry(0.1) on r iff opaque != 0, then Ry(0.9) on r controlled by
; [q > 5], the flag stripped back to |0> before its free.
;
; History: pre-3qlq the hop was the register form `if (opaque) cq_phi(r, .1);`
; with a dead result. The 3qlq migration deleted that uncontrolled phase and left
; the side block empty; bd jttf (2026-10-05) re-spelled the hop as the in-place
; Ry above. The POST-region alias twin that declines is
; control_inplace_ry_reject_stale_measure.ll.
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
; CHECK-NEXT: %[[O:[0-9]+]] = icmp eq i32 %2, 0
; CHECK-NEXT: br i1 %[[O]], label %[[JOIN:[0-9]+]], label %[[SIDE:[0-9]+]]
; the hop lowers in its OWN conditionally-executed block, ahead of the region
; CHECK:      {{^}}[[SIDE]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: br label %[[JOIN]]
; CHECK:      {{^}}[[JOIN]]:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[M]]
;
; NEG-NOT: cqrt_cswap
; NEG-NOT: call void @cqrt_x(
; NEG-NOT: phi i32
; NEG-NOT: cq_theta_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @example(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %6 = icmp eq i32 %2, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 1.000000e-01) #2
  br label %9

9:                                                ; preds = %7, %3
  %10 = phi i32 [ %8, %7 ], [ %5, %3 ]
  %11 = icmp sgt i32 %4, 5
  br i1 %11, label %12, label %14

12:                                               ; preds = %9
  %13 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2
  br label %14

14:                                               ; preds = %12, %9
  %15 = phi i32 [ %13, %12 ], [ %10, %9 ]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
