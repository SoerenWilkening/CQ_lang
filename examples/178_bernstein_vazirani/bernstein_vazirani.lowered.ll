; HAND-WRITTEN. Rules: 20 (bool x[nq] is a runtime-sized slot array: one `alloca i32, nq` of i1 handle cells, as 74), 2
; (cq_theta(false, pi/2), -O1's constant-propagated init, mints alloc_i1(0) + ry_i1 and the handle is stored in the cell; the
; second cq_theta rotates the cell's rail in place), 14 (the H^n loop, the value loop, the H^n loop and the measure loop have
; the classical bound nq and stay ROLLED classical loops; the value loop pushes its three trip-local rails per trip and a
; reverse loop pops and uncomputes them), 7 (v's |0> seed is freed directly; on the nq <= 0 path the literal 0 reaching
; `phi i32 %20` is materialised as a seed rail too, so the phi is all handles), 4 (v is zext_i1_to_i32 / shl_i32_hl / or_i32
; into fresh rails; the oracle is and_i32_hl against the runtime s, ctpop_i32, and_i32_hl 1, icmp_eq_i32_hl 0, every one a
; fresh rail), 8 (the compare rail is the branch flag; the phase arm sits on the FALSE edge of `parity == 0`, so it is the
; X-bracketed kickback), 5 (the flag and the oracle chain, then the value chain newest trip first, all before H^n rotates
; their sources), 12 (the cq_phi is under a quantum predicate: not deleted).
; Checked: x[0..nq-1] (the measured rails; m = sum x[i] << i).
; Clean: the flag, the three oracle rails (and, ctpop, and), the 3 * nq value-chain rails and the seed.
; Kept: the nq registers only (measured).
; Rotations: Ry(pi/2) on x[0..nq-1] (control 1); P(pi) on NOT flag(popcount(v & s) & 1 == 0)  [control predicate: the parity
;   of x & s is odd, i.e. (-1)^{x.s}]; Ry(-pi/2) on x[0..nq-1] (control 1).
; Expected: m = s mod 2^nq with probability 1. Replayed (state vector over the trace): bernstein_vazirani(4, 11) -> m = 11,
;   p = 1; bernstein_vazirani(5, 19) -> m = 19, p = 1; every free hits |0>.
; -O1 keeps the source structure: H^n as a rolled loop that stores 0 and calls cq_theta_i1(false, pi/2) per cell, v as an
; nq-trip accumulator loop (zext nneg i8 -> i32 of the cell, shl by the trip index, or into the carried i32 seeded by the
; literal 0), the oracle as `and`, ctpop, `and 1`, `icmp eq 0` with the cq_phi block on the FALSE edge. Each loop is guarded
; by its own `nq > 0` test. The accumulator lowering is 117's / 176's: fresh rails per trip, the handle-stack mirror after the
; kickback and before H^n rotates the cells (the _unc of zext reads the cell's unchanged value). The mirror runs only when the
; value loop ran (the same classical nq > 0 test). `v & s` has a quantum and a classical operand: the _hl template with the
; runtime literal s; ctpop is the unary intrinsic template of 56. The kickback P(pi) under `parity odd` is the phase oracle
; (-1)^{x.s}, so H^n (-1)^{x.s} H^n |0> = |s>.
source_filename = "bernstein_vazirani.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @bernstein_vazirani(i32 noundef %0, i32 noundef %1) {
  %3 = zext i32 %0 to i64    ; IR: %3 = zext i32 %0 to i64  (classical cell count)
  %4 = alloca i32, i64 %3, align 16    ; IR: %4 = alloca i8, i64 %3  (slot array of runtime length nq: one i1 handle per cell of x; rule 20)
  %5 = icmp sgt i32 %0, 0    ; IR: %5  (classical)
  br i1 %5, label %6, label %14    ; IR: br i1 %5, label %6, label %8

6:; IR: block %6
  %7 = zext nneg i32 %0 to i64    ; IR: %7  (classical bound)
  br label %8    ; IR: br label %12

8:; IR: block %12  (x[i] = false; H^n: the Ry(pi/2) loop, classical bound nq)
  %9 = phi i64 [ 0, %6 ], [ %12, %8 ]    ; IR: %13  (classical i)
  %10 = getelementptr inbounds i32, ptr %4, i64 %9    ; IR: %14  (slot of x[i])
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i8 0, ptr %14; %15 = cq_theta_i1(false, pi/2)  [register x[i], minted from the literal false]
  call void @cqrt_ry_i1(i32 %11, double 0x3FF921FB54442D18)    ; IR: %15 = cq_theta_i1(false, pi/2)  [Ry(pi/2) on x[i]]
  store i32 %11, ptr %10, align 4    ; IR: %16 = zext; store i8 %16, ptr %14  (the cell holds the handle of x[i])
  %12 = add nuw nsw i64 %9, 1    ; IR: %17  (classical)
  %13 = icmp eq i64 %12, %7    ; IR: %18  (classical)
  br i1 %13, label %14, label %8    ; IR: br i1 %18, label %8, label %12

14:; IR: block %8
  %15 = icmp sgt i32 %0, 0    ; IR: %9  (classical)
  br i1 %15, label %18, label %16    ; IR: br i1 %9, label %10, label %19

16:; IR: edge %8 -> %19 (nq <= 0: v = 0)
  %17 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %20 [ 0, %8 ]  [a |0> seed rail: the phi is all handles (rule 7)]
  br label %32    ; IR: br label %19

18:; IR: block %10
  %19 = zext nneg i32 %0 to i64    ; IR: %11  (classical bound)
  %20 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %27 [ 0, %10 ]  [v before trip 0: a |0> seed rail]
  br label %21    ; IR: br label %25

21:; IR: block %25  (v |= x[i] << i, classical bound nq)
  %22 = phi i64 [ 0, %18 ], [ %30, %21 ]    ; IR: %26  (classical i)
  %23 = phi i32 [ %20, %18 ], [ %29, %21 ]    ; IR: %27 = phi i32 [ 0, %10 ], [ %33, %25 ]  (the carried accumulator rail)
  %24 = getelementptr inbounds i32, ptr %4, i64 %22    ; IR: %28  (slot of x[i])
  %25 = load i32, ptr %24, align 4    ; IR: %29 = load i8, ptr %28  (handle of x[i]; no gate)
  %26 = call i32 @cq_template_zext_i1_to_i32(i32 %25)    ; IR: %30 = zext nneg i8 %29 to i32  [x[i] widened into a fresh rail]
  %27 = trunc nuw nsw i64 %22 to i32    ; IR: %31  (classical)
  %28 = call i32 @cq_template_shl_i32_hl(i32 %26, i32 %27)    ; IR: %32 = shl nuw i32 %30, %31  [fresh rail]
  %29 = call i32 @cq_template_or_i32(i32 %28, i32 %23)    ; IR: %33 = or i32 %32, %27  [fresh rail: the next accumulator]
  call void @cqrt_push(i32 %23)    ; IR: trip-local rails on the handle stack (rule 14): the previous accumulator
  call void @cqrt_push(i32 %26)    ; IR: ... the zext rail
  call void @cqrt_push(i32 %28)    ; IR: ... the shl rail
  %30 = add nuw nsw i64 %22, 1    ; IR: %34  (classical)
  %31 = icmp eq i64 %30, %19    ; IR: %35  (classical)
  br i1 %31, label %32, label %21    ; IR: br i1 %35, label %19, label %25

32:; IR: block %19  (the oracle)
  %33 = phi i32 [ %17, %16 ], [ %29, %21 ]    ; IR: %20 = phi i32 [ 0, %8 ], [ %33, %25 ]  (v: a rail on both edges)
  %34 = call i32 @cq_template_and_i32_hl(i32 %33, i32 %1)    ; IR: %21 = and i32 %20, %1  [v & s, s a runtime literal; fresh rail]
  %35 = call i32 @cq_template_ctpop_i32(i32 %34)    ; IR: %22 = llvm.ctpop.i32(%21)  [fresh rail]
  %36 = call i32 @cq_template_and_i32_hl(i32 %35, i32 1)    ; IR: %23 = and i32 %22, 1  [fresh rail]
  %37 = call i32 @cq_template_icmp_eq_i32_hl(i32 %36, i32 0)    ; IR: %24 = icmp eq i32 %23, 0  [the branch flag]
  call void @cqrt_not_i1(i32 %37)    ; IR: bracket: block %36 is the FALSE edge of br i1 %24 (rule 8)
  call void @cqrt_rz_i1(i32 %37, double 0x400921FB54442D18)    ; IR: block %36: cq_phi(pi)  [kickback: (-1)^{x.s}]
  call void @cqrt_not_i1(i32 %37)    ; IR: bracket
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %37, i32 %36, i32 0)    ; IR: uncompute %24
  call void @cqrt_free(i32 %37)    ; IR: release the flag (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %36, i32 %35, i32 1)    ; IR: uncompute %23
  call void @cqrt_free(i32 %36)    ; IR: release the %23 rail (|0>)
  call void @cq_template_ctpop_i32_unc(i32 %35, i32 %34)    ; IR: uncompute %22
  call void @cqrt_free(i32 %35)    ; IR: release the %22 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %34, i32 %33, i32 %1)    ; IR: uncompute %21
  call void @cqrt_free(i32 %34)    ; IR: release the %21 rail (|0>)
  %38 = icmp sgt i32 %0, 0    ; IR: (classical: did the value loop run? the mirror runs exactly when it did)
  br i1 %38, label %39, label %52    ; IR: (classical)

39:; IR: (mirror of the value loop: pops trip nq-1 down to 0 before H^n rotates the cells)
  %40 = add nsw i64 %3, -1    ; IR: (classical)
  br label %41    ; IR: (mirror)

41:; IR: reverse loop over the value trips
  %42 = phi i64 [ %40, %39 ], [ %50, %41 ]    ; IR: i of the trip being undone  (classical)
  %43 = phi i32 [ %33, %39 ], [ %46, %41 ]    ; IR: %33 of the trip being undone
  %44 = call i32 @cqrt_pop()    ; IR: the trip's shl rail (%32)
  %45 = call i32 @cqrt_pop()    ; IR: the trip's zext rail (%30)
  %46 = call i32 @cqrt_pop()    ; IR: the trip's incoming accumulator (%27)
  %47 = getelementptr inbounds i32, ptr %4, i64 %42    ; IR: (slot of x[i])
  %48 = load i32, ptr %47, align 4    ; IR: the trip's x[i] handle, reloaded (unchanged: H^n has not run yet)
  %49 = trunc nuw nsw i64 %42 to i32    ; IR: %31 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %43, i32 %44, i32 %46)    ; IR: uncompute %33
  call void @cqrt_free(i32 %43)    ; IR: release the %33 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %44, i32 %45, i32 %49)    ; IR: uncompute %32
  call void @cqrt_free(i32 %44)    ; IR: release the %32 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %45, i32 %48)    ; IR: uncompute %30
  call void @cqrt_free(i32 %45)    ; IR: release the %30 rail (|0>)
  %50 = add nsw i64 %42, -1    ; IR: (classical)
  %51 = icmp eq i64 %42, 0    ; IR: (classical)
  br i1 %51, label %52, label %41    ; IR: (classical)

52:; IR: (the join after the oracle)
  %53 = phi i32 [ %33, %32 ], [ %46, %41 ]    ; IR: the seed: incoming 0 of phi %27 (after the mirror) or of phi %20 (nq <= 0)
  call void @cqrt_free(i32 %53)    ; IR: release the seed (never written, |0>; rule 7)
  br label %54    ; IR: br i1 %24, label %37, label %36 -> block %37

54:; IR: block %37
  %55 = icmp sgt i32 %0, 0    ; IR: %38  (classical)
  br i1 %55, label %56, label %58    ; IR: br i1 %38, label %39, label %41

56:; IR: block %39
  %57 = zext nneg i32 %0 to i64    ; IR: %40  (classical bound)
  br label %62    ; IR: br label %45

58:; IR: block %41
  %59 = icmp sgt i32 %0, 0    ; IR: %42  (classical)
  br i1 %59, label %60, label %68    ; IR: br i1 %42, label %43, label %54

60:; IR: block %43
  %61 = zext nneg i32 %0 to i64    ; IR: %44  (classical bound)
  br label %70    ; IR: br label %56

62:; IR: block %45  (H^n: the Ry(-pi/2) loop, classical bound nq)
  %63 = phi i64 [ 0, %56 ], [ %66, %62 ]    ; IR: %46  (classical i)
  %64 = getelementptr inbounds i32, ptr %4, i64 %63    ; IR: %47  (slot of x[i])
  %65 = load i32, ptr %64, align 4    ; IR: %48 = load i8, ptr %47; %49 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1(i32 %65, double 0xBFF921FB54442D18)    ; IR: %50 = cq_theta_i1(%49, -pi/2)  [Ry(-pi/2) in place on x[i]]; %51/store: handle unchanged
  %66 = add nuw nsw i64 %63, 1    ; IR: %52  (classical)
  %67 = icmp eq i64 %66, %57    ; IR: %53  (classical)
  br i1 %67, label %58, label %62    ; IR: br i1 %53, label %41, label %45

68:; IR: block %54
  %69 = phi i32 [ 0, %58 ], [ %79, %70 ]    ; IR: %55  (classical m)
  ret i32 %69    ; IR: ret i32 %55

70:; IR: block %56  (the measure loop, classical bound nq)
  %71 = phi i64 [ 0, %60 ], [ %80, %70 ]    ; IR: %57  (classical i)
  %72 = phi i32 [ 0, %60 ], [ %79, %70 ]    ; IR: %58  (classical m)
  %73 = getelementptr inbounds i32, ptr %4, i64 %71    ; IR: %59  (slot of x[i])
  %74 = load i32, ptr %73, align 4    ; IR: %60 = load i8, ptr %59; %61 = trunc to i1  (handle of x[i])
  %75 = call i1 @cqrt_measure_i1(i32 %74)    ; IR: %62 = cq_measure_i1(%61)
  %76 = zext i1 %75 to i32    ; IR: %63  (classical)
  %77 = trunc nuw nsw i64 %71 to i32    ; IR: %64  (classical)
  %78 = shl nuw i32 %76, %77    ; IR: %65  (classical)
  %79 = or i32 %78, %72    ; IR: %66  (classical)
  %80 = add nuw nsw i64 %71, 1    ; IR: %67  (classical)
  %81 = icmp eq i64 %80, %61    ; IR: %68  (classical)
  br i1 %81, label %68, label %70    ; IR: br i1 %68, label %54, label %56
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_ctpop_i32(i32)
declare void @cq_template_ctpop_i32_unc(i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
