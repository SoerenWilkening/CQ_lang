; control_inplace_ry_inloop_rz_reflection.ll — ACCEPT: the in-loop Ry arm with a
; phase REFLECTION on the CONDITION register in the same body (bd
; test_C_libtooling-drbq Inc 3; the C-reachable spelling of shape S2).
; `clang -O1` output (attribute groups and metadata trimmed) for
;
;     int example(int u0, int u1) {
;       int q = u0; cq_theta(&q, 0.5);
;       int r = u1; cq_theta(&r, 0.25);
;       for (int i = 0; i < 4; i++) {
;         if (q == 5) cq_theta(&r, 0.9);   /* the in-loop controlled Ry         */
;         if (q == 7) cq_phi(0.1);         /* a branch phase on q: the reflection */
;       }
;       return cq_measure(q) + cq_measure(r);
;     }
;
; TWO THINGS IT PINS.
;
; (1) A DIAGONAL operation on the condition register in the loop body. The
;     reflection's flag is a second compare of `q`, its phase lands on that flag,
;     and its strip returns the flag to |0>, so `q`'s basis labels never move:
;     the Ry arm's condition reads the same `q` on every activation and
;     `condWireDisposition` has nothing to fence. clang -O1 LICM-hoists BOTH
;     loop-invariant compares (`%5`, `%6`) into the entry block; the pass still
;     mints each flag INSIDE the body, once per activation, from the hoisted
;     compare's operands.
;
; (2) The condition rail and the rotated rail are DISJOINT (R4), so the flag the
;     Ry mint reads is the basis the source compare describes and the
;     uncontrolled `_unc` strip returns it to |0> — per activation, exactly as
;     flat. The rotated `r` is a loop-carried handle variable (`%13`, through the
;     region merge `%17`), collapsed to its one alloc handle.
;
; Per trip the stream is: mint [q == 5], controlled Ry(0.9) on r, strip, free;
; mint [q == 7], `cqrt_rz_i1(f, 0.1)`, strip, free. Four trips, then both
; registers are measured.
;
; History: pre-3qlq the reflection was the register form `q = cq_phi(q, .1)`, an
; in-place Rz that also made `q` loop-variant so clang could not hoist the
; compare (the hoisted form then declined at P4, PRD §13.2 row W; measured
; 2026-10-05, that hoisted form now lowers). The 3qlq migration deleted the
; uncontrolled Rz and left hand-kept IR with an unhoisted compare and no
; reflection; bd jttf (2026-10-05) re-spelled the reflection as the branch phase
; above. (An `Ry` reflection here is the Grover customer and needs §13.4b — see
; control_inplace_ry_post_region_theta_cond.ll.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: br label %[[LOOP:[0-9]+]]
; CHECK:      {{^}}[[EXIT:[0-9]+]]:
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK:      {{^}}[[LOOP]]:
; CHECK-NEXT: phi i32
; the in-loop controlled Ry, its flag read off q and returned to |0>:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the reflection: a kickback on a second flag read off q:
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 1.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[G]], i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32 %{{[0-9]+}}, 4
; CHECK-NEXT: br i1 %{{[0-9]+}}, label %[[EXIT]], label %[[LOOP]]
;
; Exactly the two flag frees (the rails of q and r are measured, never freed):
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: cq_theta_si32
; NOROUTE-NOT: call void @cq_phi(
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @example(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01) #2
  %5 = icmp eq i32 %3, 5
  %6 = icmp eq i32 %3, 7
  br label %11

7:                                                ; preds = %19
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %10 = add nsw i32 %9, %8
  ret i32 %10

11:                                               ; preds = %2, %19
  %12 = phi i32 [ 0, %2 ], [ %20, %19 ]
  %13 = phi i32 [ %4, %2 ], [ %17, %19 ]
  br i1 %5, label %14, label %16

14:                                               ; preds = %11
  %15 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 9.000000e-01) #2
  br label %16

16:                                               ; preds = %14, %11
  %17 = phi i32 [ %15, %14 ], [ %13, %11 ]
  br i1 %6, label %18, label %19

18:                                               ; preds = %16
  tail call void @cq_phi(double noundef 1.000000e-01) #3
  br label %19

19:                                               ; preds = %16, %18
  %20 = add nuw nsw i32 %12, 1
  %21 = icmp eq i32 %20, 4
  br i1 %21, label %7, label %11
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare void @cq_phi(double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
