; lowering_loop_phase_accum_const.ll — ACCEPT (Phase 7.3 Inc 1, 799w.1): the
; CONST-bound in-place rotation accumulator, `clang -O1` output (attribute groups
; and metadata trimmed) for
;
;     double acck(double seed) {
;       double q = seed; cq_theta(&q, 0.5);
;       for (int i = 0; i < 4; i++) cq_theta(&q, 0.1);
;       return cq_measure(q);
;     }
;
; It lowers ROLLED IN PLACE. This is the headline Case A (the owner's phase
; accumulation / Trotterization shape). A KNOWN-≥1-trip const bound has NO
; zero-trip guard and NO exit phi: just the loop-carried header phi
; `%7 = phi [%2, %1], [%8, %5]` whose latch incoming `%8 = cq_theta(%7, 0.1)`
; peels (through the in-place rotation) back to the header phi itself, rooted at
; the `cq_theta` mint `%2`. clang -O1 does not unroll the opaque `nomerge` call
; (measured), so 7.3 lowers the rolled CFG directly.
;
; THE COLLAPSE (LoopLowering::tryCaseA): the in-place self-cycle header phi
; collapses to its single persistent rail (RAUW %7 -> %2, erase) BEFORE
; rotation lowering, so the body lowers to `cqrt_ry_f64(%h, 0.1)` over the
; loop-invariant alloc handle. The loop CFG (backedge, classical induction) is
; PRESERVED; zero measurements inserted, zero in-body frees (the rail is measured
; after L). Running the rolled loop 4 times applies Ry(0.1) four times on the one
; register, byte-identical to the manually-unrolled 4×`cqrt_ry_f64` trace.
;
; History: written for the pre-3qlq register form `q = cq_phi(q, 0.1)` (an
; in-place Rz) in the body. The 3qlq migration deleted it as an uncontrolled
; phase and left the body empty; bd jttf (2026-10-05) re-spelled the body gate as
; the in-place Ry above, which keeps the self-cycle header phi this file pins.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; Mint + Ry in the preheader (entry), in place:
; CHECK-LABEL: define double @acck(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: br label %[[LOOP:[0-9]+]]
; The exit block (placed first by clang) measures the ONE handle:
; CHECK:      {{^}}[[EXIT:[0-9]+]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[H]])
; CHECK-NEXT: ret double %[[M]]
; The rolled body: ONE in-place Ry on the loop-invariant handle, then the
; classical induction and the const bound, the backedge preserved:
; CHECK:      {{^}}[[LOOP]]:
; CHECK-NEXT: %[[I:[0-9]+]] = phi i32 [ 0, %{{[0-9]+}} ], [ %{{[0-9]+}}, %[[LOOP]] ]
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 1.000000e-01)
; CHECK-NEXT: %[[INEXT:[0-9]+]] = add nuw nsw i32 %[[I]], 1
; CHECK-NEXT: %[[DONE:[0-9]+]] = icmp eq i32 %[[INEXT]], 4
; CHECK-NEXT: br i1 %[[DONE]], label %[[EXIT]], label %[[LOOP]]
;
; Whole-module negatives: the rail phi is GONE, every front-end intrinsic is
; lowered, and Case A emits NO in-body free and NO uncompute (the rail is
; measured after L):
; NEG-NOT: phi double
; NEG-NOT: cq_theta_f64
; NEG-NOT: cq_measure_f64
; NEG-NOT: cqrt_free
; NEG-NOT: double -1.000000e-01
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define double @acck(double noundef %0) local_unnamed_addr {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #2
  br label %5

3:                                                ; preds = %5
  %4 = tail call double @cq_measure_f64(double noundef %8) #3
  ret double %4

5:                                                ; preds = %1, %5
  %6 = phi i32 [ 0, %1 ], [ %9, %5 ]
  %7 = phi double [ %2, %1 ], [ %8, %5 ]
  %8 = tail call double @cq_theta_f64(double noundef %7, double noundef 1.000000e-01) #2
  %9 = add nuw nsw i32 %6, 1
  %10 = icmp eq i32 %9, 4
  br i1 %10, label %3, label %5
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr

declare double @cq_measure_f64(double noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
