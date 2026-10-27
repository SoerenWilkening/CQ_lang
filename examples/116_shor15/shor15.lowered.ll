; HAND-WRITTEN. Rules: 2, 4, 5, 8, 9, 12, 14, 20.
; Checked: m, the three counting bits x[T-1-j] (the rails %2, %3, %4 behind the slot array; the measure loop loads each
; as %80 and measures it, %81), and y = a^x mod N (the copied-out rail %30 -> %72); the result is m | y << 8.
; Clean: every mod-exp trip rail (the product, the remainder and the select of each trip, popped and uncomputed by the
; mirror loop right after the loop), the rail holding the classical seed y = 1 (%14, popped as %37, never written) and
; the QFT^-1 Toffoli flags (%62, one per (j, k) pair, uncomputed after their kickback).
; Kept: none beyond the measured registers: the three counting rails and the y result rail, entangled as |x>|a^x mod N>.
; Rotations: (Ry, x[j], pi/2, 1) for j = 0, 1, 2 (H on |0>); then for j = 0, 1, 2 over the logical qubit x[T-1-j]:
; (P, flag, -pi / 2^(j-k), x[T-1-k] & x[T-1-j]) for each k < j, (P, x[T-1-j], pi, x[T-1-j]) (rz_i1 on the bare rail), and
; (Ry, x[T-1-j], pi/2, 1). The mod-exp is a permutation (no rotation).
; Shor order finding for N = 15, a = 7, T = 3 counting qubits, end to end: the three parts are examples
; 58 (the bool array is three i1 rails behind classical handle slots), 62 (the controlled modular multiply in a classical
; loop) and 60 (the QFT^-1 loops), composed. H|0> is Ry(pi/2) in place on each cell. Mod-exp: the condition `if (x[j])` is
; a BARE RAIL loaded from slot j, its own flag (59); the arm's mul/urem are hoisted out of the arm into fresh rails and the
; phi is one select on that rail; y is loop-carried, seeded with a rail holding the classical 1; the classical recurrence
; ap = ap*ap % N runs beside it and is pushed on the handle stack for the mirror. The loop is MIRRORED RIGHT AFTER IT
; (62's placement): the final y is copied out and every trip's rails are uncomputed while the controls x[j] still hold the
; values the trips read; the reverse trip reloads its control from the slot. After the mirror only the three counting
; rails and the y result rail remain, entangled: |x>|a^x mod N>. QFT^-1: `if (x[T-1-k] && x[T-1-j]) cq_phi` is two nested
; bare-rail branches folded into one Toffoli flag, a kickback with the classical angle, un-Toffoli, free (60);
; `if (x[T-1-j]) cq_phi(pi)` is a phase on a bare rail: cqrt_rz_i1 directly on the register (a diagonal gate needs no
; flag); then Ry(pi/2) in place (H = Ry(pi/2)·Z on a superposed qubit). The measure loop reads the slots; y is measured
; last. Replayed on a state vector: m uniform on {0, 2, 4, 6}, y in {1, 7, 4, 13}.
source_filename = "shor15.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @shor15() {
  %1 = alloca [3 x i32], align 4    ; IR: %1 = alloca [3 x i8]  (classical slots: one handle per cell of x)
  %2 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: memset(%1, 0, 3): x[0] = 0  [register x[0]]
  %3 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: memset: x[1] = 0  [register x[1]]
  %4 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: memset: x[2] = 0  [register x[2]]
  store i32 %2, ptr %1, align 4    ; IR: memset  (slot 0 holds the handle of x[0])
  %5 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 1    ; IR: (slot 1)
  store i32 %3, ptr %5, align 4    ; IR: memset  (slot 1 holds the handle of x[1])
  %6 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 2    ; IR: (slot 2)
  store i32 %4, ptr %6, align 4    ; IR: memset  (slot 2 holds the handle of x[2])
  br label %7    ; IR: br label %2

7:; preds = %entry, %2
  %8 = phi i64 [ 0, %0 ], [ %11, %7 ]    ; IR: %3  (classical j)
  %9 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %8    ; IR: %4 = getelementptr [3 x i8], ptr %1, 0, %3  (slot of x[j])
  %10 = load i32, ptr %9, align 4    ; IR: %5 = load i8, ptr %4; %6 = trunc to i1  (handle of x[j]; no gate)
  call void @cqrt_ry_i1(i32 %10, double 0x3FF921FB54442D18)    ; IR: %7 = cq_theta_i1(%6, pi/2)  [H|0>: Ry(pi/2) in place on x[j]]; %8/store: handle unchanged
  %11 = add nuw nsw i64 %8, 1    ; IR: %9  (classical)
  %12 = icmp eq i64 %11, 3    ; IR: %10  (classical)
  br i1 %12, label %13, label %7    ; IR: br i1 %10

13:
  %14 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: incoming 1 of phi %14  [y before trip 0: a rail holding the classical 1]
  br label %15

15:; preds = %pre, %21
  %16 = phi i64 [ %27, %24 ], [ 0, %13 ]    ; IR: %12  (classical j)
  %17 = phi i32 [ %26, %24 ], [ 7, %13 ]    ; IR: %13  (classical ap = 7^(2^j) mod 15)
  %18 = phi i32 [ %23, %24 ], [ %14, %13 ]    ; IR: %14 = phi i32 [ %22, %21 ], [ 1, %2 ]
  %19 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %16    ; IR: %15  (slot of x[j])
  %20 = load i32, ptr %19, align 4    ; IR: %16 = load i8, ptr %15; %17 = trunc to i1  (handle of x[j]: a bare rail, the condition of block %18 by itself)
  %21 = call i32 @cq_template_mul_i32_hl(i32 %18, i32 %17)    ; IR: %19 = mul i32 %13, %14  (block %18, hoisted: pure; commutative, classical operand to _hl)
  %22 = call i32 @cq_template_urem_i32_hl(i32 %21, i32 15)    ; IR: %20 = urem i32 %19, 15  (block %18, hoisted)
  %23 = call i32 @cq_template_select_i32(i32 %20, i32 %22, i32 %18)    ; IR: %22 = phi i32 [ %20, %18 ], [ %14, %11 ] = x[j] ? %20 : %14
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %17)    ; IR: classical ap of this trip, needed by the reverse loop
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  br label %24    ; IR: br label %21

24:; preds = %11
  %25 = mul nuw nsw i32 %17, %17    ; IR: %23  (classical)
  %26 = urem i32 %25, 15    ; IR: %24  (classical)
  %27 = add nuw nsw i64 %16, 1    ; IR: %25  (classical)
  %28 = icmp eq i64 %27, 3    ; IR: %26  (classical)
  br i1 %28, label %29, label %15    ; IR: br i1 %26, label %27, label %11

29:
  %30 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %22 of the last trip  [copied-out y = a^x mod N, entangled with x]
  call void @cqrt_copy_i32(i32 %23, i32 %30)    ; IR: %22
  br label %31

31:
  %32 = phi i64 [ 0, %29 ], [ %41, %31 ]    ; IR: reverse trip index (undoes trip 2 - j)
  %33 = phi i32 [ %23, %29 ], [ %37, %31 ]    ; IR: %22 of the trip being undone
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()    ; IR: classical ap of that trip
  %37 = call i32 @cqrt_pop()
  %38 = sub nuw nsw i64 2, %32    ; IR: j of the trip being undone  (classical)
  %39 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %38    ; IR: (slot of x[j])
  %40 = load i32, ptr %39, align 4    ; IR: the trip's control x[j], reloaded from its slot (unchanged: the QFT has not run yet)
  call void @cq_template_select_i32_unc(i32 %33, i32 %40, i32 %34, i32 %37)    ; IR: uncompute %22
  call void @cqrt_free(i32 %33)    ; IR: release the %22 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %34, i32 %35, i32 15)    ; IR: uncompute %20
  call void @cqrt_free(i32 %34)    ; IR: release the %20 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %35, i32 %37, i32 %36)    ; IR: uncompute %19
  call void @cqrt_free(i32 %35)    ; IR: release the %19 rail (|0>)
  %41 = add nuw nsw i64 %32, 1
  %42 = icmp eq i64 %41, 3
  br i1 %42, label %43, label %31

43:
  call void @cqrt_free(i32 %37)    ; IR: release incoming 1 of phi %14 (never written, holds the classical 1)
  br label %44    ; IR: br label %27

44:; preds = %done, %33
  %45 = phi i64 [ %54, %50 ], [ 0, %43 ]    ; IR: %28  (classical j of the QFT^-1)
  %46 = icmp eq i64 %45, 0    ; IR: %29  (classical)
  br i1 %46, label %50, label %47    ; IR: br i1 %29

47:; preds = %27
  %48 = sub nuw nsw i64 2, %45    ; IR: %31  (classical T - 1 - j)
  %49 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %48    ; IR: %32  (slot of x[T-1-j])
  br label %56    ; IR: br label %38

50:; preds = %53, %27
  %51 = sub nuw nsw i64 2, %45    ; IR: %34  (classical)
  %52 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %51    ; IR: %35  (slot of x[T-1-j])
  %53 = load i32, ptr %52, align 4    ; IR: %36 = load i8, ptr %35; %37 = trunc to i1  (handle of x[T-1-j]: a bare rail)
  call void @cqrt_rz_i1(i32 %53, double 0x400921FB54442D18)    ; IR: br i1 %37 -> block %56: cq_phi(pi)  [phase on the bare rail itself: a diagonal gate on the register, no flag]
  call void @cqrt_ry_i1(i32 %53, double 0x3FF921FB54442D18)    ; IR: %58 = cq_theta_i1(%37, pi/2)  [Ry in place on x[T-1-j]]; %59/store: handle unchanged
  %54 = add nuw nsw i64 %45, 1    ; IR: %60  (classical)
  %55 = icmp eq i64 %54, 3    ; IR: %61  (classical)
  br i1 %55, label %75, label %44    ; IR: br i1 %61

56:; preds = %30, %53
  %57 = phi i64 [ 0, %47 ], [ %69, %68 ]    ; IR: %39  (classical k)
  %58 = sub nuw nsw i64 2, %57    ; IR: %40  (classical T - 1 - k)
  %59 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %58    ; IR: %41  (slot of x[T-1-k])
  %60 = load i32, ptr %59, align 4    ; IR: %42 = load i8, ptr %41; %43 = trunc to i1  (handle of x[T-1-k]; no gate)
  %61 = load i32, ptr %49, align 4    ; IR: %45 = load i8, ptr %32; %46 = trunc to i1  (handle of x[T-1-j]; no gate)
  %62 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %47 = %43 & %46
  call void @cqrt_and_i1(i32 %60, i32 %61, i32 %62)    ; IR: br i1 %43 -> block %44, br i1 %46 -> block %47: one Toffoli flag
  %63 = sub nuw nsw i64 %45, %57    ; IR: %48  (classical j - k)
  %64 = trunc nuw i64 %63 to i32    ; IR: %49  (classical)
  %65 = shl nuw nsw i32 1, %64    ; IR: %50  (classical 1 << (j - k))
  %66 = uitofp nneg i32 %65 to double    ; IR: %51  (classical)
  %67 = fdiv double 0xC00921FB54442D18, %66    ; IR: %52  (classical angle -pi / 2^(j-k))
  call void @cqrt_rz_i1(i32 %62, double %67)    ; IR: block %47: cq_phi(%52)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %60, i32 %61, i32 %62)    ; IR: uncompute the %47 predicate
  call void @cqrt_free(i32 %62)    ; IR: release the flag (|0>)
  br label %68    ; IR: br label %53

68:; preds = %38
  %69 = add nuw nsw i64 %57, 1    ; IR: %54  (classical)
  %70 = icmp eq i64 %69, %45    ; IR: %55  (classical)
  br i1 %70, label %50, label %56    ; IR: br i1 %55

71:; preds = %66
  %72 = call i32 @cqrt_measure_i32(i32 %30)    ; IR: %63 = cq_measure_ui32(%22)
  %73 = shl i32 %72, 8    ; IR: %64  (classical)
  %74 = or i32 %73, %85    ; IR: %65  (classical)
  ret i32 %74    ; IR: ret i32 %65

75:; preds = %33, %66
  %76 = phi i64 [ %86, %75 ], [ 0, %50 ]    ; IR: %67  (classical j)
  %77 = phi i32 [ %85, %75 ], [ 0, %50 ]    ; IR: %68  (classical m)
  %78 = sub nuw nsw i64 2, %76    ; IR: %69  (classical)
  %79 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %78    ; IR: %70  (slot of x[T-1-j])
  %80 = load i32, ptr %79, align 4    ; IR: %71 = load i8, ptr %70; %72 = trunc to i1  (handle of x[T-1-j])
  %81 = call i1 @cqrt_measure_i1(i32 %80)    ; IR: %73 = cq_measure_i1(%72)
  %82 = zext i1 %81 to i32    ; IR: %74  (classical)
  %83 = trunc nuw nsw i64 %76 to i32    ; IR: %75  (classical)
  %84 = shl nuw nsw i32 %82, %83    ; IR: %76  (classical)
  %85 = or i32 %84, %77    ; IR: %77  (classical)
  %86 = add nuw nsw i64 %76, 1    ; IR: %78  (classical)
  %87 = icmp eq i64 %86, 3    ; IR: %79  (classical)
  br i1 %87, label %71, label %75    ; IR: br i1 %79
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
