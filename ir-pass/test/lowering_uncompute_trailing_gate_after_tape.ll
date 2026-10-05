; lowering_uncompute_trailing_gate_after_tape.ll — ACCEPT (bd
; test_C_libtooling-dm7f.2). The `clang -O1` IR (debug info stripped) of
;     static const int tbl[8] = {3,1,4,7,5,9,2,6};
;     int f(_Bool u){ _Bool b = u; cq_theta(&b, .5); int v = tbl[b];
;                     printf("%d %d\n", b, v); cq_theta(&b, -.5); return 0; }
; Declined "cq uncompute: dead chain spans divergent control-flow arms" on main
; 7b4e6359 — on straight-line code, so the message named a cause that is not
; there.
;
; WHAT DECLINED. The dead terminals are the two printed values (the `b` copy
; and the QROM load `v`); their last uses are the tape writes, so the reversal
; point was placed right after them. The DAG walk owns `b`'s register, so the
; TRAILING `cq_theta(&b, -.5)` is one of its gates — and it runs after that
; point, so it does not dominate it: the divergent-arm test fired.
;
; THE FIX (`planTerminalReversal`). A gate that does not dominate the point gets
; its next node added to the anchors; the later point is taken only if the whole
; plan proves out there (every gate dominates it, the moved-point clause-(d)
; test, at most once with matching multiplicity). Reverse program order then
; undoes the trailing gate FIRST, so each earlier `_unc` reads the label its
; forward gate read. A gate in a classical arm still declines, now truly a
; divergent arm: lowering_reject_uncompute_trailing_gate_in_arm.ll.
;
; HAND TRACE. Ry(.5)|u> = Σ_b a_b|b> on the i1 register h (born |u>, never freed).
;   qidx = zext(h); v = load(arr, qidx); zext_unc(qidx,h); free(qidx)   (the QRAM
;                                  lowering's own index discharge, as before)
;   h_cast = zext(h); tape <- h_cast; tape <- v   Σ a_b |b>|b>|tbl[b]>|tape(b,tbl[b])>
;   ry(h,-.5)                      the user's trailing gate: (Ry(-.5)_h ⊗ I) on that state
;   -- reversal, now after the trailing gate, in reverse program order --
;   ry(h,+.5)                      undoes the trailing gate exactly (same subsystem)
;   zext_unc(h_cast,h); free       h_cast holds b, h holds b again -> 0, product
;   qidx' = zext(h); load_unc(v,arr,qidx'); zext_unc(qidx',h); free(qidx'); free(v)
;                                  v holds tbl[b], arr is a const QROM -> 0
;   ry(h,-.5)                      the adjoint of the first Ry; h is then left
;                                  allocated (born |u>; recorded on the tape)
; The tape's reduced state is the source's (it recorded b and tbl[b]); h's final
; local unitary is unobservable on a leaked register whose adjoints read nothing
; else (the bd eqti premise holds: no borrowed register here).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 7, i32 5, i32 9, i32 2, i32 6], align 16
@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

define noundef i32 @f(i1 noundef zeroext %0) {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef 5.000000e-01)
  %3 = zext i1 %2 to i64
  %4 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4
  %6 = zext i1 %2 to i32
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6, i32 noundef %5)
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef -5.000000e-01)
  ret i32 0
}

; @f2: two trailing gates (`cq_theta(&b, -.5); cq_theta(&b, .25);`). Both join
; the anchors; the reversal undoes them last-first, then the rest as in @f.
define noundef i32 @f2(i1 noundef zeroext %0) {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef 5.000000e-01)
  %3 = zext i1 %2 to i64
  %4 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4
  %6 = zext i1 %2 to i32
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6, i32 noundef %5)
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef -5.000000e-01)
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 2.500000e-01)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare noundef i32 @printf(ptr nocapture noundef readonly, ...)

; CHECK-LABEL: define noundef i32 @f(
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %0)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:       %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[H]])
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[C]])
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[V]])
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT:  call void @cq_template_zext_i1_to_i32_unc(i32 %[[C]], i32 %[[H]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT:  %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[H]])
; CHECK-NEXT:  call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[I]])
; CHECK-NEXT:  call void @cq_template_zext_i1_to_i32_unc(i32 %[[I]], i32 %[[H]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[I]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[V]])
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT:  ret i32 0
; CHECK-NOT:   call void @cqrt_free(i32 %[[H]])

; CHECK-LABEL: define noundef i32 @f2(
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %0)
; CHECK:       call i32 @cqrt_tape_write_i32(
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT:  call void @cq_template_zext_i1_to_i32_unc(
; CHECK:       call void @cqrt_ry_i1(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT:  ret i32 0
