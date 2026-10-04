; lowering_uncompute_interior_irreducible_reader_accept.ll — ACCEPT (M-B
; Increment 5). The READ-SIDE half of the irreducible-cycle fence, and the proof
; that irreducible CFGs are NOT a hand-IR-only concern. Added by bd
; test_C_libtooling-4p7j's Rule-13 RE-review (finding G2).
;
; PROVENANCE: this is `clang -O1` output, not hand IR. The source is the classic
; two-entry irreducible diamond written with plain `goto`s:
;
;     int a = argc; cq_theta(&a, 0.5);
;     int x = a * a;
;     int m = 0, i = 0;
;     if (argc & 1) goto B;
;   A:  m += cq_measure(x < i); i++; if (i > 3) goto out;
;   B:  i++; goto A;
;   out: printf("%d\n", m + cq_measure(x > 100) + cq_measure(a));
;
; `-O1` leaves blocks `%5` and `%11` each with TWO predecessors (`%2`/`%11` and
; `%5`/`%2`), neither dominating the other: an irreducible cycle, so
; `LoopInfo::getLoopFor` returns null for both while they execute K times.
;
; WHAT IT PINS, AND WHY IT IS SOUND. `%h_op` (the `x = a*a` rail) is minted ONCE
; in the entry block, READ inside the cycle (`icmp slt %h_op, %7`) and read again
; in the single-entry exit `%15`. The fence keys on WRITES, never on READS: a
; consumer that reads the rail K times leaves it exactly as it found it, so a
; once-only discharge in a block that cannot repeat is still right. Refusing
; repeated READERS would leak the rail for no physics. So the exit's compare rail
; discharges, and then `%h_op` itself is `mul_i32_unc`'d against `%h` — which
; still holds its forward label, no `cqrt_ry` having run since — and freed. The
; per-iteration `%h_cmp` in `%5` is a DIFFERENT rail on every trip and correctly
; leaks (candidate selection drops a rail minted in a repeating block).
;
; THE CORRECTION IT CARRIES. Both irreducible LEAK fixtures said "C
; REACHABILITY: none today". That is true of a WRITE — an SSA write to a tainted
; value inside a cycle needs a loop-carried phi and `declineClassicalMuxes`
; refuses that upstream — and FALSE of irreducible CFGs in general. This module
; is the counter-example, and it is the read/write asymmetry earning its keep on
; a real C program rather than only on committed hand IR.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCYCLE < %t.cqd0.ll
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare noundef i32 @printf(ptr nocapture noundef readonly, ...)

define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = mul nsw i32 %3, %3
  %5 = and i32 %0, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %16

7:                                                ; preds = %2, %16 — irreducible
  %8 = phi i32 [ %17, %16 ], [ 0, %2 ]
  %9 = phi i32 [ %19, %16 ], [ 0, %2 ]
  %10 = icmp slt i32 %4, %9
  %11 = zext i1 %10 to i32
  %12 = call i32 @cq_measure_si32(i32 noundef %11)
  %13 = add nsw i32 %12, %8
  %14 = add nuw nsw i32 %9, 1
  %15 = icmp sgt i32 %9, 2
  br i1 %15, label %20, label %16

16:                                               ; preds = %7, %2 — irreducible
  %17 = phi i32 [ 0, %2 ], [ %13, %7 ]
  %18 = phi i32 [ 0, %2 ], [ %14, %7 ]
  %19 = add nuw nsw i32 %18, 1
  br label %7

20:                                               ; preds = %7
  %21 = icmp ugt i32 %4, 100
  %22 = zext i1 %21 to i32
  %23 = call i32 @cq_measure_si32(i32 noundef %22)
  %24 = add nsw i32 %23, %13
  %25 = call i32 @cq_measure_si32(i32 noundef %3)
  %26 = add nsw i32 %24, %25
  %27 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %26)
  ret i32 0
}

; The rail is minted ONCE, before the cycle:
; CHECK-LABEL: define noundef i32 @main(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[H]], i32 %[[H]])

; Read inside the cycle — the per-iteration compare rail is minted, copied by the
; zext and LEFT ALLOCATED (a rail minted in a repeating block is never a
; candidate); nothing is reversed or freed here:
; CHECK:      %[[CMP0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[OP]], i32 %7)
; CHECK-NEXT: %[[Z0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP0]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Z0]])

; And in the single-entry exit the interior discharge lands, LIFO: the exit's own
; compare rail first, then the borrowed-parent-free `mul` adjoint reading %[[H]]
; at its forward label, each rail freed right after its adjoint:
; CHECK:      %[[CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i32_hl(i32 %[[OP]], i32 100)
; CHECK-NEXT: %[[Z1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP1]])
; CHECK-NEXT: call void @cq_template_icmp_ugt_i32_hl_unc(i32 %[[CMP1]], i32 %[[OP]], i32 100)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CMP1]])
; CHECK-NEXT: call void @cq_template_mul_i32_unc(i32 %[[OP]], i32 %[[H]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Z1]])

; NOTHING is reversed or freed inside the cycle itself (the window opens at the
; in-cycle compare and closes at the exit block's compare — bd memory
; [filecheck-check-not-window-trap] — so the guard has a live extent both ends):
; NOCYCLE:      call i32 @cq_template_icmp_slt_i32_hl(
; NOCYCLE-NOT:  call void @cqrt_free(
; NOCYCLE-NOT:  _unc(
; NOCYCLE:      call i32 @cq_template_icmp_ugt_i32_hl(
